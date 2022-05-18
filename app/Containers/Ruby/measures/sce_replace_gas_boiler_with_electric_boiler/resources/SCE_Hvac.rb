class OpenStudio::Model::Model

  def zone_gas_heating_equipment(zone)
    equip = []
    # Get the heating fuels for all zone HVAC equipment
    zone.equipment.each do |equipment|
      # Get the object type
      obj_type = equipment.iddObjectType.valueName.to_s
      case obj_type
      when 'OS_AirTerminal_SingleDuct_ConstantVolume_FourPipeInduction'
        equipment = equipment.to_AirTerminalSingleDuctConstantVolumeFourPipeInduction.get
        if self.coil_heating_fuels(equipment.heatingCoil)== "NaturalGas" then equip.push(equipment) end
      when 'OS_AirTerminal_SingleDuct_ConstantVolume_Reheat'
        equipment = equipment.to_AirTerminalSingleDuctConstantVolumeReheat.get
        if  self.coil_heating_fuels(equipment.reheatCoil)   == "NaturalGas" then equip.push(equipment) end
      when 'OS_AirTerminal_SingleDuct_InletSideMixer'
        # @todo complete method
      when 'OS_AirTerminal_SingleDuct_ParallelPIUReheat'
        equipment = equipment.to_AirTerminalSingleDuctParallelPIUReheat.get
        if self.coil_heating_fuels(equipment.reheatCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_AirTerminal_SingleDuct_SeriesPIUReheat'
        equipment = equipment.to_AirTerminalSingleDuctSeriesPIUReheat.get
        if self.coil_heating_fuels(equipment.reheatCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_AirTerminal_SingleDuct_VAVHeatAndCool_Reheat'
        equipment = equipment.to_AirTerminalSingleDuctVAVHeatAndCoolReheat.get
        if self.coil_heating_fuels(equipment.reheatCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_AirTerminal_SingleDuct_VAV_Reheat'
        equipment = equipment.to_AirTerminalSingleDuctVAVReheat.get
        if self.coil_heating_fuels(equipment.reheatCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_Baseboard_Convective_Water'
        equipment = equipment.to_ZoneHVACBaseboardConvectiveWater.get
        if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_Baseboard_RadiantConvective_Water'
        equipment = equipment.to_ZoneHVACBaseboardRadiantConvectiveWater.get
        if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_FourPipeFanCoil'
        equipment = equipment.to_ZoneHVACFourPipeFanCoil.get
        if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_LowTemperatureRadiant_ConstantFlow'
        equipment = equipment.to_ZoneHVACLowTempRadiantConstFlow.get
        if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_LowTemperatureRadiant_VariableFlow'
        equipment = equipment.to_ZoneHVACLowTempRadiantVarFlow.get
        if equipment.model.version < OpenStudio::VersionString.new('3.2.0')
          if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
        else
          if equipment.heatingCoil.is_initialized
            if self.coil_heating_fuels(equipment.heatingCoil.get) == "NaturalGas" then equip.push(equipment) end
          end
        end
      when 'OS_ZoneHVAC_UnitHeater'
        equipment = equipment.to_ZoneHVACUnitHeater.get
        if self.coil_heating_fuels(equipment.heatingCoil) == "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_UnitVentilator'
        equipment = equipment.to_ZoneHVACUnitVentilator.get
        if equipment.heatingCoil.is_initialized
          if self.coil_heating_fuels(equipment.heatingCoil.get) == "NaturalGas" then equip.push(equipment) end
        end 
      when 'OS_ZoneHVAC_Baseboard_Convective_Electric'

      when 'OS_ZoneHVAC_Baseboard_RadiantConvective_Electric'

      when 'OS_ZoneHVAC_HighTemperatureRadiant'
        equipment = equipment.to_ZoneHVACHighTemperatureRadiant.get
        fuels << equipment.fuelType
      when 'OS_ZoneHVAC_IdealLoadsAirSystem'

      when 'OS_ZoneHVAC_LowTemperatureRadiant_Electric'

      when 'OS_ZoneHVAC_PackagedTerminalAirConditioner'
        equipment = equipment.to_ZoneHVACPackagedTerminalAirConditioner.get
        if self.coil_heating_fuels(equipment.heatingCoil)== "NaturalGas" then equip.push(equipment) end
      when 'OS_ZoneHVAC_PackagedTerminalHeatPump'

      when 'OS_ZoneHVAC_TerminalUnit_VariableRefrigerantFlow'

      when 'OS_ZoneHVAC_WaterToAirHeatPump'
        # We also go check what fuel serves the loop on which the WSHP heating coil is
        equipment = equipment.to_ZoneHVACWaterToAirHeatPump.get
        if self.coil_heating_fuels(equipment.heatingCoil)== "NaturalGas" then equip.push(equipment) end
      else
        OpenStudio::logFree(OpenStudio::Debug, 'openstudio.sizing.Model', "No heating fuel types found for #{obj_type}")
      end
    end
    
    return equip.uniq.sort
  end

  def replace_unitary_heating_coil(unitary_system)
    old_coil = unitary_system.heatingCoil.get
    new_coil = OpenStudio::Model::CoilHeatingElectric.new(self)
    new_coil.setName("#{unitary_system.name.get} Electric Heating Coil")
    unitary_system.resetHeatingCoil
    unitary_system.setHeatingCoil(new_coil)
    old_coil.remove
    return true
  end

  def replace_gas_coil_with_electric(coil)
    # create new electric heating coil
    new_coil = OpenStudio::Model::CoilHeatingElectric.new(self)
    removed = nil
    added = nil
    # find where coil is located
    if coil.airLoopHVAC.is_initialized
      puts coil.name.get
      airloop = coil.airLoopHVAC.get
      # get nodes
      inlet_node = coil.inletModelObject.get.to_Node.get
      outlet_node = coil.outletModelObject.get.to_Node.get
      # want to retain any spms from outlet node
      spm_clones = []
      outlet_node.setpointManagers.each {|s| spm_clones << s.clone(self)}
      # remove coil
      removed = coil.removeFromLoop
      # add new coil
      new_coil.setName("#{airloop.name.get} Electric Htg Coil")
      added = new_coil.addToNode(inlet_node)
      # add spm clones back
      spm_clones.each {|s| s.addToNode(new_coil.outletModelObject.get.to_Node.get)}
    # unitary or air terminals
    elsif coil.containingHVACComponent.is_initialized
      puts coil.name.get
      comp = coil.containingHVACComponent.get.to_actual_object
      new_coil.setName("#{comp.name.get} Electric Htg Coil")
      obj_type = comp.iddObjectType.valueName.to_s
      if obj_type.include?("Unitary") || obj_type.include?("Induction")
        if comp.heatingCoil.is_initialized && comp.heatingCoil.get == coil
          new_coil.setName("#{comp.name.get} Electric Htg Coil")
          comp.resetHeatingCoil
          added = comp.setHeatingCoil(new_coil)
        elsif comp.supplementalHeatingCoil.is_initialized && comp.supplementalHeatingCoil.get == coil
          new_coil.setName("#{comp.name.get} Electric Backup Htg Coil")
          added = comp.setSupplementalHeatingCoil(new_coil)
        end
      elsif obj_type.include? "AirTerminal"
        added = comp.setReheatCoil(new_coil)
      end
      removed = coil.remove
    # zone hvac
    elsif coil.containingZoneHVACComponent.is_initialized
      puts coil.name.get
      comp = coil.containingZoneHVACComponent.get.to_actual_object
      new_coil.setName("#{comp.name.get} Electric Htg Coil")
      added = comp.setHeatingCoil(new_coil)
      removed = coil.remove
    end

    if removed && added
      return true
    else
      return false
    end
  end

end

class OpenStudio::Model::ModelObject
  # from Julien Marrec
  # https://unmethours.com/question/17616/get-thermal-zone-supply-terminal/
  # Extend ModelObject class to add a to_actual_object method
  # Casts a ModelObject into what it actually is (OS:Node for example...)
  def to_actual_object
    obj_type = self.iddObjectType.valueName
    obj_type_name = obj_type.gsub('OS_','').gsub('_','')
    method_name = "to_#{obj_type_name}"
    if self.respond_to?(method_name)
      actual_thing = self.method(method_name).call
      if !actual_thing.empty?
          return actual_thing.get
      end
    end
    return false
  end
  
end