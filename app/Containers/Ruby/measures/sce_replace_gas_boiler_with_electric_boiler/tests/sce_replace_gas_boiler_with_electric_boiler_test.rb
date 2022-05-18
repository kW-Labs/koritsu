# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class SCEReplaceGasBoilerWithElectricBoilerTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end
  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_output_path(test_name)
    return "#{run_dir(test_name)}/#{test_name}.osm"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  def report_path(test_name)
    return "#{run_dir(test_name)}/reports/eplustbl.html"
  end

  def run_measure_test(test_name, osm_path, epw_path, args, max_unmet_hrs: 300)
    osm_path = File.expand_path(osm_path)
    epw_path = File.expand_path(epw_path)
    puts osm_path
    assert(File.exist?(osm_path))
    assert(File.exist?(epw_path))

    # create run directory if it does not exist
    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    run_dir = File.expand_path(run_dir(test_name))
    puts run_dir

    # change into run directory for tests
    start_dir = Dir.pwd
    Dir.chdir run_dir


    # copy weather file and osm to test directory
    new_osm_path = "#{run_dir}/#{File.basename(osm_path)}"
    FileUtils.cp(osm_path, new_osm_path)
    osm_path = new_osm_path
    # new_epw_path = "#{run_dir}/#{File.basename(epw_path)}"
    # FileUtils.cp(epw_path, new_epw_path)
    # epw_path = new_epw_path

    model_output_path = "#{run_dir}/#{test_name}.osm"
    sql_path = "#{run_dir}/run/eplusout.sql"
    report_path = "#{run_dir}/reports/eplustbl.html"

    # remove prior runs if they exist
    if File.exist?(model_output_path)
      FileUtils.rm(model_output_path)
    end
    if File.exist?(model_output_path.gsub('.osm',''))
      FileUtils.rm(model_output_path.gsub('.osm',''))
    end

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # apply measure to model
    model, result = apply_measure_to_model(runner, test_name, args, File.basename(osm_path), warnings_count = nil)

    # set model weather file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    assert(model.weatherFile.is_initialized)

    # save model 
    model.save(model_output_path, true)

    # run the model
    if result.value.valueName == 'Success'
      std = Standard.build("NREL ZNE Ready 2017")
      puts '\nRUNNING MODEL...'

      std.model_run_simulation_and_log_errors(model, run_dir)

      # check that the model ran successfully
      assert(File.exist?(sql_path))
    end

    # check that the model ran successfully and generated a report
    assert(File.exist?(model_output_path))
    assert(File.exist?(sql_path))
    assert(File.exist?(report_path))

    # set runner variables
    runner.setLastEpwFilePath(epw_path)
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path))

    if !runner.lastEnergyPlusSqlFile.empty?
      sql = runner.lastEnergyPlusSqlFile.get
      model.setSqlFile(sql)

      # test for unmet hours
      errs = []
      unmet_heating_hrs = std.model_annual_occupied_unmet_heating_hours(model)
      unmet_cooling_hrs = std.model_annual_occupied_unmet_cooling_hours(model)
      unmet_hrs = std.model_annual_occupied_unmet_hours(model)
      if unmet_hrs
        if unmet_hrs > max_unmet_hrs
          errs << "For #{test_name} there were #{unmet_heating_hrs.round(1)} unmet occupied heating hours and #{unmet_cooling_hrs.round(1)} unmet occupied cooling hours (total: #{unmet_hrs.round(1)}), more than the limit of #{max_unmet_hrs}." if unmet_hrs > max_unmet_hrs
        else
          puts "There were #{unmet_heating_hrs.round(1)} unmet occupied heating hours and #{unmet_cooling_hrs.round(1)} unmet occupied cooling hours (total: #{unmet_hrs.round(1)})."
        end
      else
        errs << "For #{test_name} could not determine unmet hours; simulation may have failed."
      end

      # calculate EUIs to determine if HVAC EUI is appropriate
      annual_eui = std.model_annual_eui_kbtu_per_ft2(model)
      int_lighting_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Interior Lighting').round(1)
      ext_lighting_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Exterior Lighting').round(1)
      int_equipment_elec_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Interior Equipment').round(1)
      int_equipment_gas_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Natural Gas', 'Interior Equipment').round(1)
      int_equipment_eui = (int_equipment_elec_eui + int_equipment_gas_eui).round(1)
      refrigeration_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Refrigeration').round(1)
      shw_elec_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Water Systems').round(1)
      shw_gas_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Natural Gas', 'Water Systems').round(1)
      shw_eui = (shw_elec_eui + shw_gas_eui).round(1)
      fan_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Fans').round(1)
      pump_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Pumps').round(1)
      cooling_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Cooling').round(1)
      heating_elec_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Electricity', 'Heating').round(1)
      heating_gas_eui = std.model_annual_eui_kbtu_per_ft2_by_fuel_and_enduse(model, 'Natural Gas', 'Heating').round(1)
      heating_eui = (heating_elec_eui + heating_gas_eui).round(1)
      hvac_eui = (fan_eui + pump_eui + cooling_eui + heating_eui).round(1)
      puts "Annual EUI (kBtu/ft^2): #{annual_eui.round(1)}, split:"
      puts "exterior lighting: #{ext_lighting_eui}"
      puts "interior lighting: #{int_lighting_eui}"
      puts "equipment: #{int_equipment_eui} (#{int_equipment_elec_eui} elec / #{int_equipment_gas_eui} gas)"
      puts "refrigeration: #{refrigeration_eui}"
      puts "service hot water: #{shw_eui} (#{shw_elec_eui} elec / #{shw_gas_eui} gas)"
      puts "HVAC #{hvac_eui} (fans: #{fan_eui}, pumps: #{pump_eui}, cooling: #{cooling_eui}, heating: #{heating_eui} (#{heating_elec_eui} elec / #{heating_gas_eui} gas))"

      if annual_eui > 100
        # don't expect EUIs to be above 100 unless there are very high internal loads
        errs << "The annual eui is #{annual_eui.round(1)} kBtu/ft^2, higher than expected for an NZE building." unless (int_equipment_eui + int_lighting_eui) > 70
      end

      assert(errs.empty?, errs.join('\n'))
    end

    # change back directory
    Dir.chdir(start_dir)
  end

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(runner, test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = SCEReplaceGasBoilerWithElectricBoiler.new

    if runner.nil? 
      # create an instance of a runner
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    end

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + model_name)
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]), "could not set #{arg.name} to #{args[arg.name]}.")
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # save the model to test output directory
    output_file_path = model_output_path(test_name)
    unless model_name.nil?
      model.save(output_file_path, true)
    end

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count, "warning count (#{result.warnings.size}) did not match expectation (#{warnings_count})") end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    return model, result
  end

  def test_apply_measure
    test_name = (__method__).to_s
    args = {}

    osm_path = File.dirname(__FILE__) + '/in.osm'
    epw_path = File.dirname(__FILE__) + '/in.epw'

    run_measure_test(test_name, osm_path, epw_path, args)
  end

end
