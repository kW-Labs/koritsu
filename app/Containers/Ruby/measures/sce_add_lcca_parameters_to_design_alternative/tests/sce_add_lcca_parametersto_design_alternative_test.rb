# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class SCEAddLCCAParameterstoDesignAlternativeTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = SCEAddLCCAParameterstoDesignAlternative.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('lcc_name', arguments[count += 1].name)
    assert_equal('remove_costs', arguments[count += 1].name)
    assert_equal('study_period', arguments[count += 1].name)
    assert_equal('demolition_cost', arguments[count += 1].name)
    assert_equal('material_cost', arguments[count += 1].name)
    assert_equal('om_cost', arguments[count += 1].name)
    assert_equal('om_frequency', arguments[count += 1].name)
    assert_equal('replacement_cost', arguments[count += 1].name)
    assert_equal('expected_life', arguments[count += 1].name)
    assert_equal('remaining_life', arguments[count += 1].name)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = SCEAddLCCAParameterstoDesignAlternative.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['lcca_name'] = 'Alt 1'
    args_hash['remove_costs'] = true
    args_hash['study_period'] = 0
    args_hash['demolition_cost'] = 10000
    args_hash['material_cost'] = 35000



    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Fail', result.value.valueName)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = SCEAddLCCAParameterstoDesignAlternative.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['lcca_name'] = 'Alt 1'
    args_hash['remove_costs'] = true
    args_hash['study_period'] = 25
    args_hash['demolition_cost'] = 10000
    args_hash['material_cost'] = 35000
    args_hash['om_cost'] = 3000
    args_hash['om_frequency'] = 3
    args_hash['expected_life'] = 30
    args_hash['replacement_cost'] = 40000
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    assert(result.info.size == 0)
    assert(result.warnings.empty?)

    # check that there is now 1 space
    assert_equal(4, model.getLifeCycleCosts.size)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_output.osm"
    model.save(output_file_path, true)
  end
end
