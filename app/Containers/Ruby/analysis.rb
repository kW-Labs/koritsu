require 'fileutils'
require 'json'
require 'pathname'
require 'openstudio'
require 'zip'
require 'open3'

class Analysis
  attr_accessor :data, :debug

  # directory locations relative to this file
  PROJECT_REL_PATH = "../../../../storage/app/projects"
  GEM_REL_PATH = "../.bundle/install/ruby/2.7.0/gems"
  WEATHER_REL_PATH = "../weather"
  OSA_TEMPLATE_PATH = "../osa_template/osa_template_single_run.json"

  def initialize(projects_dir = File.expand_path(PROJECT_REL_PATH,__FILE__), base_gem_path = File.expand_path(GEM_REL_PATH,__FILE__), debug = false)
    @projects_dir = projects_dir
    @base_gem_path = base_gem_path
    @debug = debug
    @project_path = "" # path to project: /Koritsu_projects/project_id
    @run_dir = "" # path to run subfolder in @project_path, e.g. /Koritsu_projects/project_id/Base
    @run_name = "" # alternative_name field from input json
    @log = []
    @summary = { "success" => false, "error_msg" => "", "created_project" => false , "created_run_dir" => false, "created_seed" => false, "copied_weather_file" => false, "created_osw" => false, "created_osa" => false, "ran_analysis" => false, "analysis_id" => nil, "project_path" => "", "debug" => @debug, "log" => []}
    @model_measures = []
    @reporting_measures = []
    @eplus_measures = []
    @is_base = false
    @is_alt = false
    @has_weather_file = false
    @success = false
    @error_msg = ""
    @all_measure_dirs = self.find_bundle_measure_paths
  end

  def summary
    return @summary
  end

  def measure_dirs
    return @all_measure_dirs
  end

  def set_debug(debug)
    @debug = debug
    @summary['debug'] = debug
  end

  def set_error(msg)
    @summary['error_msg'] = msg
    self.set_response
    return false
  end

  def set_response
    @summary['success'] =  @success
    @summary['log'] = @log
  end

  def log_entry(msg)
    if @debug
      @log.push(msg)
    end
  end

  def read_json(data)
    begin
      if File.extname(data) == ".json"
        @data = JSON.parse(File.read(data))
      else
        @data = JSON.parse(data)
      end

      return true
    rescue Exception => e
      self.log_entry(e)
      return self.set_error('Could not Parse Json')
    end
  end

  def create_analysis(data = "")
    # check for missing input
    if data == ""
      return self.set_error('Missing Json file/path')
    else
      # read in input
      self.read_json(data)
    end

    # initialize required input if missing
    @project_id = @data.key?("project_id") ? @data["project_id"].to_s : ""
    @project_name = @data.key?("project_name") ? @data["project_name"]: ""
    @measures = @data.key?("measures") ? @data['measures']: []
    @run_name = @data.key?("alternative_name") ? @data["alternative_name"] : ""
    
    # check for missing required input
    if @project_name == ""
      return self.set_error('Missing project_name')
    end

    if @run_name == ""
      return self.set_error("Missing Alternative Name")
    end 

    if @project_id == ""
      return self.set_error('Missing project_id')
    else
      @project_path = File.join(@projects_dir, @project_id)
      if !self.create_project
        return false
      else
        @summary["project_path"] = @project_path
      end
    end

    if !@data.key?("weather_file_name")
      return self.set_error('Missing Weather File')
    else
      if !self.copy_weather_file
        return false
      end
    end

    if @measures.empty?
      return self.set_error("No Measures have been specified. Aborting")
    else
      self.make_measures
    end

    if self.create_osw
      @summary['success']= self.create_osa_from_template_with_osw
    end

    self.set_response

    if @debug
      puts @log
    end
  
    return true
  end

  def create_project()
    # make project dir
    created_project = self.make_project_dir
    if created_project
      @summary['created_project'] = true
    else
      return self.set_error("Could not create Project Directory")
    end

    # make run dir
    created_run_dir = self.make_run_dir(@run_name)
    if created_run_dir
      @summary['created_run_dir'] = created_run_dir
    else
      return self.set_error("Could not create run directory")
    end

    # set run type
    set_run_type

    if @is_base
      created_seed = self.make_base_seed
      @summary['created_seed'] = created_seed
      if(created_project and created_seed)
        @model_path = @project_path;
        File.open(File.join(@run_dir,"#{@project_name}_base_input.json"),"w") do |f|
          f.write(@data.to_json)
        end
      else
        return self.set_error('Could not create project seed')
      end
    else # @is_alt = true
      base_seed = self.get_base_seed
      if base_seed
        File.open(File.join(@run_dir, "#{@project_name}_#{@run_name}_input.json"),"w") do |f|
          f.write(@data.to_json)
        end
      else
        return self.set_error('Could not find completed Base run to populate alternative seed')
      end
    end

    return true
  end

  def make_base_seed()
    begin
      model = OpenStudio::Model::Model.new()
      model.getYearDescription.setDayofWeekforStartDay("Sunday")
      @seed_path = File.join(@run_dir, "#{@project_name}_#{@data['alternative_name']}.osm")
      model.save(@seed_path, true)
      return true
    rescue Exception => e
      self.log_entry(e)
      return false
    end

    return true
  end

  # gets completed base model from server
  def get_base_seed()
    begin
      # look for in.osm in project_dir/Base/results
      base_results_dir = File.join(@project_path, "/Base/results")
      base_seed_path = File.join(base_results_dir, "in.osm")
      @seed_path = "#{@run_dir}/#{@project_name}_#{@data['alternative_name']}.osm"
      FileUtils.cp(base_seed_path, @seed_path)
      return true
    rescue Exception => e
      self.log_entry(e)
      return false
    end
  end

  def set_run_type()
    if @run_name == "Base"
      @is_base = true
    else
      @is_alt = true
    end
  end


  def make_project_dir()
    begin
      unless File.directory? @project_path
        log_entry("Creating project directory #{@project_path}.")
        FileUtils.mkdir_p(@project_path)
      else
        log_entry("Project directory #{@project_path} exists.")
      end

      run_dir_results = "#{@project_path}/downloads"
      FileUtils.mkdir_p(run_dir_results)
      FileUtils.chmod "go=wrx", run_dir_results
      @summary['project_path'] = @project_path
      return true
    rescue
      return false
    end
  end

  def make_run_dir(run_name)
    begin
      @run_dir = File.join(File.join(@project_path, run_name))
      unless File.directory?(@run_dir)
        log_entry("Creating run directory #{@run_dir}")
        FileUtils.mkdir_p(@run_dir)
      else
        log_entry("Run directory #{@run_dir} exists. Contents will be overwritten.")
        FileUtils.rm_rf(Dir.glob("#{@run_dir}/*"))
      end

      run_dir_results = "#{@run_dir}/results"
      FileUtils.mkdir_p(run_dir_results)
      FileUtils.chmod "go=wrx", run_dir_results

      return true
    rescue
      return false
    end
  end

  def copy_weather_file()
    begin
      weather_lib_path = File.expand_path(WEATHER_REL_PATH,__FILE__)
      # puts __FILE__
      # puts weather_lib_path
      epw_basename = File.basename(@data["weather_file_name"], ".epw")
      files = Dir.glob(File.join(weather_lib_path,"#{epw_basename}.*"))
      if files.empty?
        return self.set_error("EPW file #{epw_basename}.epw not found!")
      else
        dest = File.join(@project_path, "weather")
        unless File.directory? dest
          FileUtils.mkdir_p dest
        end
        files.each {|f| FileUtils.cp(f, dest) }
        @has_weather_file = true
        @summary['copied_weather_file'] = true
      end
    rescue Exception => e
      self.log_entry(e)
      return false
    end
    return true
  end

  def find_measure_type(measure_path)
    bcl_measure = OpenStudio::BCLMeasure.load(measure_path)
    if bcl_measure.is_initialized
      bcl_measure = bcl_measure.get
    else
      self.log_entry("Cannot find measure at #{measure_path}")
    end
    return bcl_measure.measureType.valueName
  end

  def find_bundle_measure_paths
    bundle_measure_paths = []

    # add path to non-gem measures
    bundle_measure_paths << File.expand_path('../measures',__FILE__)

    self.log_entry("Getting measure directories for bundle installed measure gems")
    gems = Dir.entries(@base_gem_path)
    gems.each do |gem|
      gem = "#{@base_gem_path}/#{gem}/lib/measures"
      next if ! Dir.exists?(gem)
      bundle_measure_paths.push(gem)
    end

    self.log_entry("found #{bundle_measure_paths.size} measure directories")
    self.log_entry("bundle_measure_paths:#{bundle_measure_paths.inspect}")

    return bundle_measure_paths
  end

  def find_measure_dir(measure_name)
    measure_dir = nil
    @all_measure_dirs.each do |dir|
      Pathname(dir).children.each do |path|
        if path.basename.to_s == measure_name
          measure_dir = path
        end
      end
    end
    if measure_dir.nil?
      return false
    else
      return measure_dir
    end
  end

  def make_measures
    @measures.each do |measure|
     name = measure.key?("name") ? measure["name"]: ""
     if(name == "")
       self.log_entry("Measure has Missing Name")
     else
       self.log_entry("Adding #{name} to workflow")
       measure_step = OpenStudio::MeasureStep.new(name)
       measure_dir = self.find_measure_dir(name)
       if !measure_dir
         self.log_entry("Could not find location for #{name}.")
       end

       measure['arguments'].each do |k,v|
         measure_step.setArgument(k,v)
       end

       if measure_dir != false
         measure_type = find_measure_type(measure_dir.to_s)
         self.log_entry("#{name} -----> #{measure_type}")
       end 
	   
       case measure_type
       when "ModelMeasure"
         @model_measures.push(measure_step)
       when "ReportingMeasure"
         @reporting_measures.push(measure_step)
       when 'EnergyPlusMeasure'
         @eplus_measures.push(measure_step)
       else
         self.log_entry("Could not Add Measure Type #{measure_type}")
       end
     end

    end
  end

  def create_osw
    begin
      @osw = OpenStudio::WorkflowJSON.new
      @all_measure_dirs.each do |path|
        @osw.addMeasurePath(File.absolute_path(path))
      end

      if @is_base
        @osw.addFilePath("base")
      else
        # TODO: add alternative
      end

      if @has_weather_file
        @osw.addFilePath("weather")
        @osw.setWeatherFile(@data['weather_file_name'])
      end

      @osw.setSeedFile(File.basename(@seed_path))
      dir = Dir.pwd
      Dir.chdir(@project_path)
      @osw.setMeasureSteps(OpenStudio::MeasureType.new('ModelMeasure'),@model_measures) unless @model_measures.empty?
      @osw.setMeasureSteps(OpenStudio::MeasureType.new('ReportingMeasure'),@reporting_measures) unless @reporting_measures.empty?
      @osw.setMeasureSteps(OpenStudio::MeasureType.new('EnergyPlusMeasure'),@eplus_measures) unless @eplus_measures.empty?
      Dir.chdir(dir)
      @osw.saveAs(File.join(@run_dir,"#{@project_name}_#{@run_name}.osw"))
      @summary['created_osw'] = true
      return true
    rescue Exception => e
      self.log_entry(e)
      return false
    end
  end

  def create_osa_from_template_with_osw(make_zip = true)

      # osa_template_path = OpenStudio::Path.new("osa_template/osa_template_single_run.json")
      osa_template_path = File.expand_path(OSA_TEMPLATE_PATH,__FILE__)
      osw_json = JSON.parse(@osw.to_s)

      # load a copy of template OSA file
      project_name = osw_json["seed_file"].gsub(".osm","")
      osa_name = "#{@project_name}_osa"
      analysis_dir = "#{@run_dir}/analysis"
      FileUtils.mkdir_p(analysis_dir)
      osa_target_path = "#{analysis_dir}/#{@project_name}_#{@run_name}.json"
      zip_path = "#{analysis_dir}/#{@project_name}_#{@run_name}.zip"
      json = File.read(osa_template_path.to_s)
      osa = JSON.parse(json)
      self.log_entry("loading template OSA")

      runner = OpenStudio::Measure::OSRunner.new(@osw)
      workflow = runner.workflow

      # update name and display name
      osa["analysis"]["display_name"] = "#{osw_json["seed_file"].gsub(".osm","")} Single Run"
      osa["analysis"]["name"] = "#{osw_json["seed_file"].gsub(".osm","")}_singlerun"

      # hash to name measures with multiple instances
      measures_used_hash = {} # key is measure value is an array of instances, will help me to index name when used multiple times
      var_used_hash = {} # key variable name value is number of instances of similar name, will help me to index name when used multiple times
      workflow_index = 0

      if make_zip

        analysis_script_dir = 'analysis_scripts'
        Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|

          Dir["#{analysis_script_dir}/**/*"].each do |file|
            zip_file.add(file.sub(analysis_script_dir+'/','scripts/'),file)
            self.log_entry("#{file} added to zip")
          end

          Dir["#{@project_path}/weather/**/*"].each do |file|
            zip_file.add(file.sub("#{@project_path}/weather/","weather/"),file)
            self.log_entry("#{file} added to zip")
          end

          Dir["#{@run_dir}/*.osm"].each do |file|
            zip_file.add(file.sub("#{@run_dir}/","seeds/"),file)
            self.log_entry("#{file} added to zip")
          end
        end
      end

      # setup seed file
      if workflow.seedFile.is_initialized
        seed_file = workflow.seedFile.get
        self.log_entry("setting seed file to #{seed_file}")
        osa["analysis"]["seed"]= {"file_type" => "OSM","path" => "./seeds/#{seed_file}"}
      end

      # setup weather file
      if @has_weather_file
        if workflow.weatherFile.is_initialized
          weather_file = workflow.weatherFile.get
          self.log_entry("setting weather_file to #{weather_file}")
          osa["analysis"]["weather_file"]= {"file_type" => "EPW","path" => "./weather/#{weather_file}"}
          # TODO: add custom weather file
          # code below isn't necessary unless OSW weather file is not in the repo 'weather' directory
          if make_zip
            # source_path = workflow.findFile(weather_file).get
            # puts "confirming weather file is in analysis zip"
            # zip_file.addFile(source_path,OpenStudio::Path.new("weather/#{weather_file}"))
          end
        end
      end

      # todo - I can't figure out how to setup an OSA to run with null seed or weather. While it is valid for an OSW, I don't know if it is valid for an OSA

      # define discrete variables (nested hash of measure instance name and argument name. Value is an array of variable values)
      # desc_vars = var_mapping(var_set,osw_path)
      desc_vars = {}
      desc_args = {}

      # populate workflow of OSA with steps from OSW
      self.log_entry("processing source OSW")
      desc_vars_validated = {}
      workflow.workflowSteps.each do |step|
        self.log_entry(step.class)
        if step.to_MeasureStep.is_initialized

          measure_step = step.to_MeasureStep.get
          measure_dir_name = measure_step.measureDirName
          source_path = workflow.findMeasure(measure_dir_name.to_s).get
          self.log_entry(" - gathering data for #{measure_dir_name} from #{source_path}.")

          if make_zip
            self.log_entry("adding measure files to zip")
            self.log_entry(measure_dir_name)
            self.log_entry(source_path)
            Zip::File.open(zip_path) do |zip_file|
              Dir["#{source_path}/**/*"].each do |file|
                zip_file.add(file.sub(source_path.to_s+'/',"measures/#{measure_dir_name}/"),file)
              end
            end
          end

          # check if measure already exists
          if measures_used_hash.has_key?(measure_dir_name)
            measures_used_hash[measure_dir_name] += 1
            inst_name = "#{measure_dir_name}_#{measures_used_hash[measure_dir_name]}"
          else
            inst_name = measure_dir_name
            measures_used_hash[measure_dir_name] = 1
          end

          new_workflow_measure = {}
          new_workflow_measure["name"] = inst_name.downcase # would be better to snake_case
          new_workflow_measure["display"] = inst_name.downcase # would be better to snake_case
          new_workflow_measure["measure_definition_directory"] = "./measures/#{measure_dir_name}"
          if measure_step.arguments.size > 0
            new_workflow_measure["arguments"] = []
          end

          measure_step.arguments.each do |k,v|
            if v.to_s == "true" then v = true end
            if v.to_s == "false" then v = false end

            # change arguments per var_set specifications
            # inst_name is measure_dir_name unless more than one instance exists when _# is added starting with _2
            if desc_args.has_key?(inst_name) && desc_args[inst_name].has_key?(k) && desc_args[inst_name][k] != v
              custom_val = desc_args[inst_name][k]
              self.log_entry("For #{k} argument in measure named #{inst_name} value from template OSW is being chagned to #{custom_val}")
              arg_hash = {"name" => k,"value" => custom_val}
            else
              arg_hash = {"name" => k,"value" => v}
            end

            # setup variables and arguments
            if desc_vars.has_key?(inst_name) && desc_vars[inst_name].has_key?(k)

              # update validated hash for reporting of script
              if !desc_vars_validated.has_key?(inst_name) then desc_vars_validated[inst_name] = {} end
              if !desc_vars_validated[inst_name].has_key?(k) then desc_vars_validated[inst_name][k] = [] end

              # setup variable
              if !new_workflow_measure.has_key?("variables")
                new_workflow_measure["variables"] = []
              end
              new_var = {}
              new_workflow_measure['variables'].push(new_var)
              new_var['argument'] = arg_hash
              if var_used_hash.has_key?(k)
                var_used_hash[k] += 1
                new_var['display_name'] = "#{k}_#{var_used_hash[k]}"
              else
                var_used_hash[k] = 1
                new_var['display_name'] = k
              end
              new_var['variable_type'] = 'variable'
              new_var['variable'] = true
              new_var['static_value'] = v
              new_var['uncertainty_description'] = {}
              new_var['uncertainty_description']['type'] = 'discrete'
              new_var['uncertainty_description']['attributes'] = []
              attribute_hash = {}
              attribute_hash['name'] = 'discrete'
              values_and_weights = []
              desc_vars[inst_name][k].each do |val|
                # weight not important for DOE but may want to store with values for other use cases
                values_and_weights.push({'value' => val, 'weight' => 1.0/desc_vars[inst_name][k].size})
                desc_vars_validated[inst_name][k].push(val)
              end
              attribute_hash['values_and_weights'] = values_and_weights
              new_var['uncertainty_description']['attributes'].push(attribute_hash)
            else
              # setup argument
              new_workflow_measure["arguments"].push(arg_hash)
              if !new_workflow_measure.has_key?("variables")
                new_workflow_measure["variables"] = []
              end
            end

          end

          new_workflow_measure["workflow_index"] = workflow_index
          workflow_index += 1
          osa["analysis"]["problem"]["workflow"].push(new_workflow_measure)

        else
          #puts "This step is not a measure"
        end

      end

      # save OSW file
      self.log_entry("saving modified OSA")
      osa.to_json
      File.open(osa_target_path, "w") do |f|
        f.puts JSON.pretty_generate(osa)
      end

      # report number of variables
      measures_with_vars = []
      missing_measures_with_vars = []
      vars = []
      var_vals = []
      self.log_entry("-----")
      # desc_vars
      # desc_vars_validated
      desc_vars.each do |k,v|
        next if v.size == 0
        if ! desc_vars_validated.has_key?(k)
          missing_measures_with_vars.push(k)
          self.log_entry("**** OSW at doesn't have a measure named #{k}, requested variables will be ignored for osa generation. ****")
        else
          measures_with_vars.push(k)
          v.each do |k2,v2|

            if ! desc_vars_validated[k].has_key?(k2)
              self.log_entry("**** OSW at doesn't have a measure argument named #{k2} for measure #{k}, requested variable will be ignored for osa generation. ****")
            else
              self.log_entry("#{v2.size} values for #{k} #{k2}: #{v2.inspect}")
              vars.push(k2)
              var_vals.push(v2.size)
            end
          end
        end
      end
      self.log_entry("-----")
      self.log_entry("#{measures_with_vars.size} measures have variables #{measures_with_vars.inspect}.")
      self.log_entry("The analysis has #{vars.size} variables #{vars.inspect}.")
      self.log_entry("With DOE algorithm the analysis will have #{var_vals.inject(:*)} datapoints.")
      if vars.size < 2
        self.log_entry("**** warning analysis has only one variable, may not work with some algorithms that require 2 or more variaibles. *****")
      end

      @osa_path = osa_target_path
      @summary['created_osa'] = true
      return true
  end

  def get_analysis_id(l)
    if l.include? "analysis created with ID:"
       results = l.split(':', -1)
       @summary["analysis_id"] = results[1].lstrip.chomp
    end
  end

  def run_analysis(cli_path, server_ip = 'localhost')
    cmd = "#{cli_path} run_analysis --debug --verbose \"#{File.absolute_path(@osa_path)}\" \"http://#{server_ip}:8080\" -a single_run"
    self.log_entry(cmd)

	  begin
      return_value = Open3.popen2e(cmd) do |stdin, stdout_stderr, wait_thread|
        Thread.new do
          stdout_stderr.each {|l| self.get_analysis_id(l) }
        end

        wait_thread.value
		  end

      response = return_value.exitstatus == 1 ? false : true
      @summary['ran_analysis'] = response
      @summary['success'] = response

    rescue Exception => e
      self.log_entry(e)
      return false
    end

    return response;
  end

  def sanitize_filename(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end

end
