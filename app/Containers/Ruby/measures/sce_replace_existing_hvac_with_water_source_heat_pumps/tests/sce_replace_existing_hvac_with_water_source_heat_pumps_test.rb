# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class SCEReplaceExistingHVACWithWaterSourceHeatPumpsTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = SCEReplaceExistingHVACWithWaterSourceHeatPumps.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

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
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
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

    return model
  end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = SCEReplaceExistingHVACWithWaterSourceHeatPumps.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('template', arguments[0].name)
    assert_equal('doas', arguments[1].name)
    assert_equal('doas_cool', arguments[2].name)
    assert_equal('doas_cool_cop', arguments[3].name)
    assert_equal('doas_heat', arguments[4].name)
    assert_equal('doas_heat_cop', arguments[5].name)
    assert_equal('loop_cool', arguments[6].name)
    assert_equal('loop_heat', arguments[7].name)
    assert_equal('loop_heat_cop', arguments[8].name)
    assert_equal('cool_cop', arguments[9].name)
    assert_equal('heat_cop', arguments[10].name)
  end

  def test_bad_efficiency
    args = {}
    args['doas_cool_cop'] = 8
    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, nil, 'Fail')
    args.clear
    args['cool_cop'] = -1
    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, nil, 'Fail')
    args.clear
    args['heat_cop'] = 10.1
    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, nil, 'Fail')
  end

  def test_add_doas

    args = {}
    args['template'] = "DEER 2015"
    args['doas'] = true
    args['doas_cool'] = 'DX'
    args['doas_cool_cop'] = 3.2
    args['doas_heat'] = 'Gas Furnace'
    args['doas_heat_cop'] = 0.8
    args['loop_cool'] = 'Cooling Tower'
    args['loop_heat'] = 'Gas Boiler'
    args['loop_heat_cop'] = 0.8
    args['cool_cop'] = 3.0
    args['heat_cop'] = 3.0

    model = apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'in.osm', warnings_count = nil)
  end
end
