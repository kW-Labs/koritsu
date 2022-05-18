# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class SCEDemandResponseTest < Minitest::Test
  # def setup
  # end



  def skip_test_run_measure
    test_name = (__method__).to_s
    args = {}
    osm_path = File.dirname(__FILE__) + '/in.osm'
    epw_path = File.dirname(__FILE__) + '/in.epw'


  end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = SCEDemandResponse.new

    # make an empty workspace
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(6, arguments.size)
    assert_equal('demand_target', arguments[0].name)
    assert_equal('ext_lt_lim_frac', arguments[1].name)
    assert_equal('int_lt_lim_frac', arguments[2].name)
    assert_equal('equip_lim_frac', arguments[3].name)
    assert_equal('max_heat_reset', arguments[4].name)
    assert_equal('max_cool_reset', arguments[5].name)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = SCEDemandResponse.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # make an empty workspace
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)

    # check that there are no thermal zones
    assert_equal(0, workspace.getObjectsByType('DemandManagerAssignmentList'.to_IddObjectType).size)

    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to bad value
    demand_target = arguments[0].clone
    assert(demand_target.setValue(-100))
    argument_map['demand_target'] = demand_target

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    assert_equal('Fail', result.value.valueName)

    # check that there are still no thermal zones
    assert_equal(0, workspace.getObjectsByType('DemandManagerAssignmentList'.to_IddObjectType).size)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = SCEDemandResponse.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load test model workspace
    workspace = OpenStudio::Workspace::load(OpenStudio::Path.new(File.dirname(__FILE__) + '/in.idf')).get
    # # make an empty workspace
    # workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)

    # check that there are no thermal zones
    assert_equal(0, workspace.getObjectsByType('DemandManagerAssignmentList'.to_IddObjectType).size)

    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    demand_target = arguments[0].clone
    ext_lt_lim_frac = arguments[1].clone
    int_lt_lim_frac = arguments[2].clone
    equip_lim_frac = arguments[3].clone
    max_heat_reset = arguments[4].clone
    max_cool_reset = arguments[5].clone
    assert(demand_target.setValue(50))
    assert(ext_lt_lim_frac.setValue(0.9))
    assert(int_lt_lim_frac.setValue(0.2))
    assert(equip_lim_frac.setValue(0.6))
    assert(max_heat_reset.setValue(60))
    assert(max_cool_reset.setValue(76))
    argument_map['demand_target'] = demand_target
    argument_map['ext_lt_lim_frac'] = ext_lt_lim_frac
    argument_map['int_lt_lim_frac'] = int_lt_lim_frac
    argument_map['equip_lim_frac'] = equip_lim_frac
    argument_map['max_heat_reset'] = max_heat_reset
    argument_map['max_cool_reset'] = max_cool_reset

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    assert_equal('Success', result.value.valueName)

    # check that there is now 1 thermal zones
    assert_equal(1, workspace.getObjectsByType('DemandManagerAssignmentList'.to_IddObjectType).size)

    # # check that zone is properly named
    # zone = workspace.getObjectsByType('Zone'.to_IddObjectType)[0]
    # assert(!zone.getString(0).empty?)
    # assert_equal('New Zone', zone.getString(0).get)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    workspace.save(output_file_path, true)
  end
end
