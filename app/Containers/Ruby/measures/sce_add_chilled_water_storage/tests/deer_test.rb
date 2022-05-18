require_relative "../../measure_test_helper.rb"
require_relative '../measure.rb'

building_type = "OfL"
template = "DEER 2015"
hvac_system = "SVVE"
climate_zone = "CEC T24-CEC9"
measure = SCEAddChilledWaterStorage.new
args = {
  'stor_cap' => 300,
  'charge_hours' => '18:00 - 08:00'
}
SCEMeasuresTest.create_prototype_building_test(building_type, template, hvac_system, climate_zone, measure, args, true, true, true, true)