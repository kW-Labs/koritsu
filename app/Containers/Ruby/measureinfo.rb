# This is a convenience file for outputting measure arguments for the given measures to csv files

require 'openstudio'
require 'csv'
require 'fileutils'
require 'json'
require 'pathname'

module MeasureInfo

  def self.bundle_base_gem_path
    # return '/data/github/koritsu-www/app/Containers/Ruby/.bundle/install/ruby/2.7.0/gems'
    gem_rel_path = "../.bundle/install/ruby/2.7.0/gems"
    return File.expand_path(gem_rel_path,__FILE__)
  end

  def self.find_bundle_measure_paths
    bundle_measure_paths = []

    # add path to non-gem measures
    bundle_measure_paths << File.expand_path('../measures',__FILE__)

    # puts "Getting measure directories for bundle installed measure gems"
    gems = Dir.entries(bundle_base_gem_path)
    gems.each do |gem|
      # check if has lib/measures
      gem = "#{bundle_base_gem_path}/#{gem}/lib/measures"
      next if ! Dir.exists?(gem)
      bundle_measure_paths << gem
    end

    # puts "found #{bundle_measure_paths.size} measure directories"
    # puts "bundle_measure_paths:#{bundle_measure_paths.inspect}"

    return bundle_measure_paths
  end

  def self.find_measure_dir(measure_name)
    all_measure_dirs = find_bundle_measure_paths
    # all_measure_dirs << './measures'
    measure_dir = nil
    all_measure_dirs.each do |dir|
      Pathname(dir).children.each do |path|
        if path.basename.to_s == measure_name
          measure_dir = path
        end
      end
    end
    if measure_dir.nil? 
      return false 
    else return measure_dir
    end
  end

  def self.find_measure_type(measure_path)

    bcl_measure = OpenStudio::BCLMeasure.load(measure_path)
    if bcl_measure.is_initialized
      bcl_measure = bcl_measure.get
    else
      return nil 
    end

   if defined?(bcl_measure.measureType)   
    return bcl_measure.measureType.valueName
   else 
     return nil
   end

  end

  def self.all_measure_dirs

    measure_dirs = []
    measure_gem_dirs = find_bundle_measure_paths
    measure_gem_dirs.each do |gem_measure_dir|
      # get subdirs within gem_measure_dir as strings and add to measure_dirs array
      measure_dirs.concat(Pathname(gem_measure_dir).children.select(&:directory?).map{|p| p.to_s})
    end

    return measure_dirs
  end



  # computes the measure arguments of all meausures in bundled gems for a model at model_path
  # test call: ruby -r "./measureinfo.rb" -e "MeasureInfo.compute_measure_arguments_for_model('../Koritsu_projects/24_2021-02-28_13-46-58/alt/in.osm','ReduceLightingLoadsByPercentage')"
  def self.compute_measure_arguments_for_model(model_path, measure_name = nil)
    # check if file exists at path
    if !File.file?(model_path)
      return false
    end

    if measure_name.nil?
      return false
    end

    measure_dirs = all_measure_dirs
    # puts measure_dirs
    include_measure_info_json = []
    measure_dirs.each do |dir|
      measure_type = find_measure_type(dir)
      next if measure_type == "ReportingMeasure"
      next unless dir.downcase.include?(measure_name.downcase)
      if measure_type == "ModelMeasure"
      measure_info = `openstudio measure --compute_arguments "#{model_path}" "#{dir}"`
      elsif measure_type == "EnergyPlusMeasure"
        # load osm and translate osm to idf
        path = OpenStudio::Path.new(model_path)
        vt = OpenStudio::OSVersion::VersionTranslator.new
        # don't write FT messages
        OpenStudio::Logger.instance.standardOutLogger.disable
        if OpenStudio::exists(path)
          # load model
          model = vt.loadModel(path).get
          # translate to workspace
          ft = OpenStudio::EnergyPlus::ForwardTranslator.new
          ws = ft.translateModel(model)
          # temporarily save workspace to idf
          idf_path = "#{File.dirname(model_path)}/#{File.basename(model_path)}.idf"
          idf = File.new(idf_path, 'w')
          idf.write(ws)
          idf.close
          # compute args on idf
          measure_info = `openstudio measure --compute_arguments "#{idf_path}" "#{dir}"`
          # delete idf
          File.delete(idf_path) if File.exist?(idf_path)
        else
          return false
        end
      end

      measure_info_json = JSON.parse(measure_info)
      # arg_hashes << measure_info
      if measure_info_json["class_name"].downcase ==  measure_name.downcase.split('_').join('')
        include_measure_info_json = measure_info_json
        break
      end
    end

    puts include_measure_info_json.to_json
    return include_measure_info_json

  end

  def self.compute_and_save_measure_info_to_json(model_path, measure_name = nil)

    info = compute_measure_arguments_for_model(model_path, measure_name = nil)

    save_dir = File.dirname(model_path)
    if measure_name.nil?
      json_filename = "All Measure Args.json"
    else
      json_filename = "#{measure_name} Args.json"
    end

    File.open(File.join(save_dir, json_filename),"w") do |f|
      f << arg_hashes.to_json
    end

  end


end
