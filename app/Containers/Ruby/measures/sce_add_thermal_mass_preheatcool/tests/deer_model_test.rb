require_relative '../../measure_test_helper.rb'
require_relative '../measure.rb'

building_type = "OfS"
template = "DEER 2015"
hvac_system = "DXGF"
hvac_systems = [
  "DXGF", 
  # "SVVG", 
  # "WLHP"
]
climate_zone = "CEC T24-CEC9"
measure = SCEAddThermalMassPreheatCool.new
args = {
  'cool_temp_shift'=> 5.0,
  'heat_temp_shift'=> 0.0,
  'start_hour_shift' => 3.0,
  'tcap' => 1.0
       }

# SCEMeasuresTest.create_prototype_building_test(building_type, template, hvac_system, climate_zone, measure, args, true, false, false, true)
SCEMeasuresTest.create_run_model_tests([building_type], [template], hvac_systems, [climate_zone], measure, args, true, true, true, true)