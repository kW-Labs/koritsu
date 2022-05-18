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
measure = SCEAddElectricStorage.new
args = {'stor_op'=>'Facility Demand Leveling',
        'demand_target'=>30,
       }

# SCEMeasuresTest.create_prototype_building_test(building_type, template, hvac_system, climate_zone, measure, args, true, false, false, true)
SCEMeasuresTest.create_run_model_tests([building_type], [template], hvac_systems, [climate_zone], measure, args, true, true, true, true)