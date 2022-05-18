require_relative '../measureinfo.rb'
require 'json'

def create_spec(measure_name)
  model_path = "../in.osm"
  # get measure info hash
  measure_info = MeasureInfo.compute_measure_arguments_for_model(model_path, measure_name)
  
  if measure_info.empty?
    puts "#{measure_name} NOT FOUND!"
    return false
  else
    return measure_info
  end

  # # create default spec pairs
  # spec = {
  #   "$schema" => "http://json-schema.org/schema#",
  #   "$id" => "#{measure_name}",
  #   "type" => "object",
  #   "dir" => "#{measure_info["measure_dir"]}",
  #   "description" => "#{measure_info["description"]}",
  #   "required" => [],
  #   "properties" => {},
  # }

  # # loop through measure args and populate spec
  # measure_info["arguments"].each do |arg_hash|
  #   if arg_hash["required"] == true
  #     spec["required"] << arg_hash["name"]
  #   end
    
  #   # hash to hold argument properties
  #   arg = {}

  #   # convert type
  #   case arg_hash["type"]
  #   when 'Double'
  #     arg["type"] = "number"
  #     arg["min"] = nil
  #     arg["max"] = nil
  #   when 'Integer'
  #     arg["type"] = "integer"
  #     arg["min"] = nil
  #     arg["max"] = nil
  #   when 'String'
  #     arg["type"] = "string"
  #   when 'Choice'
  #     arg["type"] = "string"
  #     arg["enum"] = arg_hash["choice_display_names"]
  #   when 'Bool'
  #     arg["type"] = "boolean"
  #   end

  #   arg["default_value"] = arg_hash["default_value"]
  #   arg["display_name"] = arg_hash["display_name"]
  #   arg["description"] = arg_hash["description"]

  #   # nest arg properties
  #   obj = {arg_hash["name"] => arg}

  #   # merge into properties
  #   spec["properties"].merge!(obj)
  # end

  # return spec
end


measure_list_path = "/home/edr/koritsu-www/app/Containers/Koritsu/WebApp/UI/WEB/Views/src/schema/alternative_measures.json"

measure_list = JSON.parse(File.read(measure_list_path))


# loop through measure list and create spec
measure_list.each do |h|
  name = h["value"]
  puts name
  # create save path
  save_dir = File.expand_path("../../Koritsu/WebApp/UI/WEB/Views/src/schema/", File.dirname(__FILE__))
  # test save dir
  # save_dir = File.expand_path("./schema/", File.dirname(__FILE__))
  save_path = File.join(save_dir, name + ".json")
  puts save_path
  # skip if file already exists
  next if File.exist?(save_path)
  # create spec
  spec = create_spec(name)
  if spec
    # write to file
    File.open(save_path, 'w') do |f|
      f << JSON.pretty_generate(spec)
    end
  end
end