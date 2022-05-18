require 'json'
require_relative './analysis.rb'

json_string = ARGV[0]
if json_string.nil?
  puts JSON.pretty_generate([:error_msg => "No json string or path specified.", :success => false])
else
  json_file_path = json_string.gsub('\\','/')

  cli_path = ARGV[1]
  if cli_path.nil?
    cli_path = "/System/Volumes/Data/Users/jorge/code/OpenStudio-PAT/depend/OpenStudio-server/bin/openstudio_meta"
  end

  server_ip = ARGV[2]
  if server_ip.nil?
    server_ip = "34.222.109.73"
  end

  analysis = Analysis.new()
  analysis.set_debug(ARGV[3])
  if analysis.create_analysis(json_string)
    analysis.run_analysis(cli_path, server_ip)
  end
  puts JSON.pretty_generate(analysis.summary)

end
