require 'openstudio'

require 'csv'
# TODO: this should its own gem because this file may be useful in various workflows
module OpenStudio
  module Weather
    class Epw
      attr_accessor :filename
      attr_reader :city
      attr_reader :state
      attr_reader :country
      attr_accessor :data_type
      attr_reader :wmo
      attr_reader :lat
      attr_reader :lon
      attr_reader :gmt
      attr_reader :elevation
      attr_accessor :data_period

      # access to all the weather data in array of arrays
      attr_reader :header_data
      attr_accessor :weather_data

      def initialize(filename)
        @filename = filename
        @city = ''
        @state = ''
        @country = ''
        @data_type = ''
        @wmo = ''
        @lat = ''
        @lon = ''
        @gmt = ''
        @elevation = ''
        @valid = false

        @header_data = []
        @weather_data = []
        process_header
      end

      def self.load(filename)
        raise "EPW file does not exist: #{filename}" unless File.file?(filename)
        f = OpenStudio::Weather::Epw.new(filename)
      end

      def to_kml(xml_builder_obj, url)
        xml_builder_obj.Placemark do
          xml_builder_obj.name @city
          xml_builder_obj.visibility '0'
          xml_builder_obj.description do
            xml_builder_obj.cdata!('<img src="kml/ep_header8.png" width=180 align=right><br><table><tr><td colspan="2">'\
                           "<b>#{@city}</b></href></td></tr>\n" +
                                       # "<tr><td></td><td><b>Data Type</td></tr>\n"+
                                       "<tr><td></td><td>WMO <b>#{@wmo}</b></td></tr>\n" +
                                       # "<tr><td></td><td>E   3� 15'   N 36� 43'</td></tr>\n"+
                                       # "<tr><td></td><td><b>25</b> m</td></tr>\n"+
                                       "<tr><td></td><td>Time Zone GMT <b>#{@gmt}</b> hours</td></tr>\n" +
                                       # "<tr><td></td><td>ASHRAE Std 169 Climate Zone <b>4A - Mixed - Humid</b></td></tr>\n"+
                                       # "<tr><td></td><td>99% Heating DB=<b>3.1</b>, 1% Cooling DB=<b>33.2</b></td></tr>\n"+
                                       # "<tr><td></td><td>HDD18 <b>1019</b>, CDD10 <b>2849</b></td></tr>\n"+
                                       "<tr><td></td><td>URL #{url}</td></tr></table>")
          end
          xml_builder_obj.styleUrl '#weatherlocation'
          xml_builder_obj.Point do
            xml_builder_obj.altitudeMode 'absolute'
            xml_builder_obj.coordinates "#{@lon},#{@lat},#{elevation}"
          end
        end
      end

      def valid?
        return @valid
      end

      def save_as(filename)
        File.delete filename if File.exist? filename
        FileUtils.mkdir_p(File.dirname(filename)) unless Dir.exist?(File.dirname(filename))

        CSV.open(filename, 'wb') do |csv|
          @header_data.each { |r| csv << r }
          csv << [
            'DATA PERIODS', @data_period[:count], @data_period[:records_per_hour], @data_period[:name],
            @data_period[:start_day_of_week], @data_period[:start_date], @data_period[:end_date]
          ]
          @weather_data.each { |r| csv << r }
        end

        true
      end

      # Append the weather data (after data periods) to the end of the weather file. This allows
      # for the creation of multiyear weather files. Note that the date/order is not checked. It assumes
      # that the data are being added at the end is the more recent data
      #
      # @param filename [String] Path to the file that will be appended
      def append_weather_data(filename)
        to_append = OpenStudio::Weather::Epw.load(filename)

        prev_length = @weather_data.size
        @weather_data += to_append.weather_data

        prev_length + to_append.weather_data.size == @weather_data.size
      end

      def metadata_to_hash
        {
          city: @city,
          state: @state,
          country: @country,
          data_type: @data_type,
          wmo: @wmo,
          latitude: @lat,
          longitude: @lon,
          elevation: @elevation
        }
      end

      private

      # initialize
      def process_header
        header_section = true
        row_count = 0

        # this breaks in Ruby 2.5.x
        CSV.foreach(@filename) do |row|
          row_count += 1

          if header_section
            if row[0].match(/data.periods/i)
              @data_period = {
                count: row[1].to_i,
                records_per_hour: row[2].to_i,
                name: row[3],
                start_day_of_week: row[4],
                start_date: row[5],
                end_date: row[6]
              }

              header_section = false

              next
            else
              @header_data << row
            end
          else
            @weather_data << row
          end

          # process only header row
          # LOCATION,Adak Nas,AK,USA,TMY3,704540,51.88,-176.65,-10.0,5.0
          if row_count == 1
            @valid = true

            @city = row[1].tr('/', '-')
            @state = row[2]
            @country = row[3]
            @data_type = row[4]
            if @data_type.match(/TMY3/i)
              @data_type = 'TMY3'
            elsif @data_type.match(/TMY2/i)
              @data_type = 'TMY2'
            elsif @data_type.match(/TMY/i)
              @data_type = 'TMY'
            end
            @wmo = row[5]
            @wmo.nil? ? @wmo = 'wmoundefined' : @wmo = @wmo.to_i
            @lat = row[6].to_f
            @lon = row[7].to_f
            @gmt = row[8].to_f
            @elevation = row[9].to_f
          end
        end
      end
    end
  end
end


# get list of epw filenames
def get_filenames(dir)
  filenames = []
  Dir.chdir(dir)
  files = Dir.glob("*.epw")
  filenames = files.map!{|f| f.gsub('.epw','')}
  return filenames
end

# parse stat file for climate zone
def get_climate_zone(stat_file)
  # get climate zone from stat file
  text = nil
  File.open(stat_file) do |f|
    text = f.read.force_encoding('iso-8859-1')
  end

  # Get Climate zone.
  # - Climate type "3B" (ASHRAE Standard 196-2006 Climate Zone)**
  # - Climate type "6A" (ASHRAE Standards 90.1-2004 and 90.2-2004 Climate Zone)**
  regex = /Climate type \"(.*?)\" \(ASHRAE Standards?(.*)\)\*\*/
  match_data = text.match(regex)
  if match_data.nil?
    puts "Can't find ASHRAE climate zone in stat file."
  else
    cz = match_data[1].to_s.strip
  end

  return cz
end

def get_latlong(stat_file)
  text = nil
  # File.open(stat_file) do |f|
  #   text = f.read.force_encoding('iso-8859-1')
  # end
  lines = File.open(stat_file).to_a

  # deg_regex = /^([0-8][0-9]|90)°\s([0-4][0-9]|59)'$/
  # min_regex = /^([0-8][0-9]|90)°\s[0-5][0-9]'$/

  lat_dir = nil
  lat_deg = nil
  lat_min = nil
  lon_dir = nil
  lon_deg = nil
  lon_min = nil
  regex = /(N|S|E|W|[0-9][0-9]*[0-9]*|90)/
  # text.each_line do {|l| l[]}
  # match = text.match(regex)
  match = lines.at(3).scan(regex)
  puts match
  if match.nil?
    puts "Can't find latitude/longitude."
    # puts text[3]
  else
    lat_dir = match[0][0].to_s.strip
    lat_deg = match[1][0].to_f
    lat_min = match[2][0].to_f
    lon_dir = match[3][0].to_s.strip
    lon_deg = match[4][0].to_f
    lon_min = match[5][0].to_f
  end

  if lat_dir == "S"
    lat_mult = -1
  else lat_mult = 1
  end

  if lon_dir == "W"
    lon_mult = -1
  else lon_mult = 1
  end

  lat_decimal = lat_mult * ((lat_deg) + (lat_min/60))
  lon_decimal = lon_mult * ((lon_deg) + (lon_min/60))

  return lat_decimal.round(4), lon_decimal.round(4)
end

def load_epw(epw_path)
  epw = OpenStudio::EpwFile.load(OpenStudio::Path.new(epw_path))
  
  if epw.is_initialized
    epw = epw.get
  else puts "something went wrong"
  end
  return epw
end

def get_city(epw_file)
  return epw_file.city
end

def get_state(epw_file)
  return epw_file.state
end

dir = Dir.pwd
files = get_filenames(dir)

weather_info = []
files.each do |name|
  obj = {}
  # epw_file = (load_epw(File.join(dir, "#{name}.epw"))
  epw_file = OpenStudio::Weather::Epw.load(File.join(dir, "#{name}.epw"))
  stat_file = File.join(dir, "#{name}.stat")
  puts name
  obj["state"] = get_state(epw_file)
  obj["latitude"], obj["longitude"] = get_latlong(stat_file)
  obj["location"] = get_city(epw_file)
  obj["weather_file_name"] = "#{name}.epw"
  obj["climate_zone"] = get_climate_zone(stat_file)
  weather_info << obj
end

require 'json'
File.open("weather_info.json","w") do |f|
  # f.write(weather_info.to_json)
  f.write(JSON.pretty_generate(weather_info))
end

