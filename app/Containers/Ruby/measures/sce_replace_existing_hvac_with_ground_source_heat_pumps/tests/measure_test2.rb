require_relative "../../measure_test_helper.rb"
require_relative '../measure.rb'

# class SCEReplaceExistingHVACWithGroundSourceHeatPumpsTest < SCEMeasuresTest

  # def test_against_prototype
    building_type = "OfL"
    template = "DEER 2015"
    hvac_system = "DXGF"
    climate_zone = "CEC T24-CEC9"
    measure = SCEReplaceExistingHVACWithGroundSourceHeatPumps.new
    args = {
      'template'=>'DEER 2015',
      'doas' => true,
      'cool_cop' => 3.2,
      'heat_cop' => 2.9
    }
    SCEMeasuresTest.create_prototype_building_test(building_type, template, hvac_system, climate_zone, measure, args, true, true, true, true)
  # end
# end
