require 'openstudio'
require 'openstudio-standards'
require 'openstudio/measure/ShowRunnerOutput'
require 'json'
require 'fileutils'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)

# Create a base class for testing SCE measures
class SCEMeasuresTest < Minitest::Test

  def setup
    # Make a directory to save the resulting models
    @test_dir = "#{Dir.pwd}/output"
    if !Dir.exists?(@test_dir)
      Dir.mkdir(@test_dir)
    end
    # # Make a file to store the model comparisons
    # @results_csv_file = "#{@test_dir}/prototype_test_results.csv"
    # # Add a header row on file creation
    # if !File.exist?(@results_csv_file)
    #   File.open(@results_csv_file, 'a') do |file|
    #     file.puts "building_type,template,climate_zone,fuel_type,end_use,legacy_val,osm_val,percent_error,difference,absolute_percent_error"
    #   end
    # end
    # # Make a file that combines all the run logs
    # @combined_results_log = "#{@test_dir}/run.log"
    # if !File.exist?(@combined_results_log)
    #   File.open(@combined_results_log, 'a') do |file|
    #     file.puts "Started @ #{Time.new}"
    #   end
    # end    
  end

  def SCEMeasuresTest.create_run_model_tests(building_types, 
    templates, 
    hvac_systems, 
    climate_zones, 
    measure,
    args,
    create_models = true,
    run_models = true,
    compare_results = true,
    debug = false)
  
    building_types.each do |building_type|
      templates.each do |template|
        hvac_systems.each do |hvac_system|
          climate_zones.each do |climate_zone|
            create_prototype_building_test(building_type, template, hvac_system, climate_zone, measure, args, create_models, run_models, compare_results, debug)
          end
        end
      end
    end

  end

  def apply_measure_to_model(measure, args, model, result_value = 'Success')
    # create instance of runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    assert(!model.nil?)

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
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    return model
  end

  def SCEMeasuresTest.create_prototype_building_test(building_type,
    template,
    hvac_system,
    climate_zone,
    measure,
    args,
    create_models,
    run_models,
    compare_results,
    debug)

    method_name = "test_#{building_type}-#{template}-#{hvac_system}-#{climate_zone}".gsub(' ','_')

    define_method(method_name) do

      # start time
      start_time = Time.new

      # Reset the log for this test
      reset_log
      
      # Paths for this test run
      
      input_model_name = "#{building_type}-#{template}-#{hvac_system}-#{climate_zone}"
      output_model_name = "#{input_model_name}-#{measure.class.name}"

      test_dir = "#{@test_dir}/#{method_name}"
      if !Dir.exist?(test_dir)
        Dir.mkdir(test_dir)
      end

      in_run_dir = "#{test_dir}/#{input_model_name}"
      if !Dir.exists?(in_run_dir)
        Dir.mkdir(in_run_dir)
      end
      in_sim_dir = "#{in_run_dir}/AnnualRun"
      in_osm_path = "#{in_run_dir}/#{input_model_name}.osm"
      
      out_run_dir = "#{test_dir}/#{output_model_name}"
      if !Dir.exists?(out_run_dir)
        Dir.mkdir(out_run_dir)
      end
      out_sim_dir = "#{out_run_dir}/AnnualRun"
      out_osm_path = "#{out_run_dir}/#{output_model_name}.osm"

      model = nil
      # create standard for running the annual simulation
      standard = Standard.build("#{template}")
      base_results = nil
      prop_results = nil

      # Create the model, if requested
      if create_models
        prototype_creator = Standard.build("#{template}_#{building_type}_#{hvac_system}")
        model = prototype_creator.model_create_prototype_model(climate_zone, nil, in_run_dir, debug)

        # If the model was not created successfully,
        # create and save an empty model. Tests will fail
        # because there will be errors in the log.
        if !model
          model = OpenStudio::Model::Model.new
        end

        # Save the final osm
        model.save(in_osm_path, true)

        if run_models
          FileUtils.rm_rf(in_sim_dir)
          standard.model_run_simulation_and_log_errors(model, in_sim_dir)
          base_results = prototype_creator.model_results_by_end_use_and_fuel_type(model)
        end

        # run measure and save resulting mode
        out_model = apply_measure_to_model(measure, args, model, 'Success')

        out_model.save(out_osm_path, true)

        if run_models
          FileUtils.rm_rf(out_sim_dir)
          standard.model_run_simulation_and_log_errors(out_model, out_sim_dir)
          prop_results = prototype_creator.model_results_by_end_use_and_fuel_type(out_model)
        end

      end

      # # Run the simulation, if requested
      # if run_models

      #   # Delete previous run directories if they exist
      #   FileUtils.rm_rf(in_sim_dir)
      #   FileUtils.rm_rf(out_sim_dir)


      #   standard.model_run_simulation_and_log_errors(model, in_sim_dir)
      #   standard.model_run_simulation_and_log_errors(out_model, out_sim_dir)

      # end           

      # Compare the results against the legacy idf files if requested
      if compare_results

        results = []
        results << ['Fuel Type', 'End Use', 'Prototype', 'Measure', 'Diff', 'Percent Diff']

        if base_results.nil? || prop_results.nil?
          puts "Results not found"
          return false
        end
          
        prop_results.each_key do |end_use_fuel_type|
          end_use = end_use_fuel_type.split('|')[0]
          fuel_type = end_use_fuel_type.split('|')[1]

          base_value = base_results["#{end_use}|#{fuel_type}"]
          prop_value = prop_results["#{end_use}|#{fuel_type}"]

          diff = nil
          percent_error = nil
          if base_value > 0 && prop_value > 0
            percent_error = ((prop_value - base_value)/base_value) * 100
            diff = base_value - prop_value
          elsif base_value > 0 && prop_value.abs < 1e-6
            percent_error = 100
            diff = base_value - prop_value
          elsif prop_value > 0 && base_value.abs < 1e-6
            percent_error = 100
            diff = prop_value - base_value
          else
            percent_error = 0
            diff = 0
          end

          results << [fuel_type, end_use, base_value, prop_value, diff, percent_error ]
        end

        results_file_path = "#{test_dir}/prototype_results_comparison.csv"
        CSV.open(results_file_path, 'w') do |file|
          results.each do |line|
            file << line
          end
        end
      end
            
      # Calculate run time
      run_time = Time.new - start_time
            
      # Report out errors
      log_file_path = "#{test_dir}/openstudio-standards.log"
      messages = log_messages_to_file(log_file_path, debug)
      errors = get_logs(OpenStudio::Error)         
            
      # # Copy errors to combined log file
      # File.open(@combined_results_log, 'a') do |file|
      #   file.puts "*** #{model_name}, Time: #{run_time.round} sec ***"
      #   messages.each do |message|
      #     file.puts message
      #   end
      # end
            
      # Assert if there were any errors
      # assert(errors.size == 0, errors)

    end
  end



end