require 'openstudio'
require_relative '../resources/SCE_Hvac.rb'
include OpenStudio::Model

m = Model.new
a = AirLoopHVAC.new(m)
cc = CoilCoolingDXSingleSpeed.new(m)
hc1 = CoilHeatingGas.new(m)
f = FanSystemModel.new(m)
spm = SetpointManagerScheduled.new(m, ScheduleRuleset.new(m))

cc.addToNode(a.supplyOutletNode)
hc1.addToNode(a.supplyOutletNode)
f.addToNode(a.supplyOutletNode)
spm.addToNode(hc1.outletModelObject.get.to_Node.get)

a.supplyComponents.each {|c| puts c.name.get}
spm = hc1.outletModelObject.get.to_Node.get.setpointManagers.first
spm_clones = []
hc1.outletModelObject.get.to_Node.get.setpointManagers.each {|s| spm_clones << s.clone(m)}
# puts spm_clones
# puts "***************************"

hc2 = CoilHeatingGas.new(m)

u = AirLoopHVACUnitarySystem.new(m)
u.setHeatingCoil(hc2)
puts hc2.airLoopHVAC.is_initialized

a2 = AirLoopHVAC.new(m)
u.addToNode(a2.supplyOutletNode)

puts hc2.airLoopHVAC.is_initialized
# hc3 = CoilHeatingGas.new(m)
# oas = AirLoopHVACOutdoorAirSystem.new(m, ControllerOutdoorAir.new(m))
# hc3.addToNode(oas.outboardOANode.get)
# a2 = AirLoopHVAC.new(m)
# oas.addToNode(a2.supplyOutletNode)
# puts oas.components

# hc4 = CoilHeatingGas.new(m)
# z = ZoneHVACPackagedTerminalAirConditioner.new(m, ScheduleRuleset.new(m), FanSystemModel.new(m), hc4, CoilCoolingDXSingleSpeed.new(m))


m.getCoilHeatingGass.each do |coil|
  puts coil.name.get
  if coil.airLoopHVAC.is_initialized
    puts coil.airLoopHVAC.get.name.get
  end
  if coil.containingHVACComponent.is_initialized
    puts coil.containingHVACComponent.get.to_actual_object.name.get
  end
  if coil.containingStraightComponent.is_initialized
    puts coil.containingStraightComponent.get.to_actual_object.name.get
  end
  if coil.containingZoneHVACComponent.is_initialized
    puts coil.containingZoneHVACComponent.get.to_actual_object.name.get
  end
end




# # new coil
# hc2 = CoilHeatingElectric.new(m)
# inlet_node = hc1.inletModelObject.get.to_Node.get
# hc1.removeFromLoop

# a.supplyComponents.each {|c| puts c.name.get}
# puts m.getSetpointManagerScheduleds

