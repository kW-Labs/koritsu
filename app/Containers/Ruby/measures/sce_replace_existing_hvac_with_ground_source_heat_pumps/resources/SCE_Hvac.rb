# author: Eric Ringold, kW Engineering
# extend Standards
class Standard
  # Creates a DOAS system with terminal units for each zone.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio model object
  # @param thermal_zones [Array<OpenStudio::Model::ThermalZone>] array of zones to connect to this system
  # @param system_name [String] the name of the system, or nil in which case it will be defaulted
  # @param doas_type [String] DOASCV or DOASVAV, determines whether the DOAS is operated at scheduled,
  #   constant flow rate, or airflow is variable to allow for economizing or demand controlled ventilation
  # @param doas_control_strategy [String] DOAS control strategy
  # @param cooling_source [String] name of cooling source component: WSHP, DX (2 speed)
  # @param heating_source [String] name of heating source component: WSHP, DX (2 speed)
  # @param hvac_op_sch [String] name of the HVAC operation schedule, default is always on
  # @param min_oa_sch [String] name of the minimum outdoor air schedule, default is always on
  # @param min_frac_oa_sch [String] name of the minimum fraction of outdoor air schedule, default is always on
  # @param fan_maximum_flow_rate [Double] fan maximum flow rate in cfm, default is autosize
  # @param econo_ctrl_mthd [String] economizer control type, default is Fixed Dry Bulb
  #   If enabled, the DOAS will be sized for twice the ventilation minimum to allow economizing
  # @param include_exhaust_fan [Bool] if true, include an exhaust fan
  # @param clg_dsgn_sup_air_temp [Double] design cooling supply air temperature in degrees Fahrenheit, default 65F
  # @param htg_dsgn_sup_air_temp [Double] design heating supply air temperature in degrees Fahrenheit, default 75F
  # @return [OpenStudio::Model::AirLoopHVAC] the resulting DOAS air loop
  def model_add_doas_custom(model,
                            thermal_zones,
                            system_name: nil,
                            doas_type: 'DOASCV',
                            cooling_source: 'DX',
                            cooling_eff: 3.0,
                            heating_source: 'DX',
                            heating_eff: 2.5,
                            condenser_loop: nil,
                            hvac_op_sch: nil,
                            min_oa_sch: nil,
                            min_frac_oa_sch: nil,
                            fan_maximum_flow_rate: nil,
                            econo_ctrl_mthd: 'NoEconomizer',
                            include_exhaust_fan: true,
                            demand_control_ventilation: false,
                            doas_control_strategy: 'NeutralSupplyAir',
                            clg_dsgn_sup_air_temp: 60.0,
                            htg_dsgn_sup_air_temp: 70.0)

    # Check the total OA requirement for all zones on the system
    tot_oa_req = 0
    thermal_zones.each do |zone|
      tot_oa_req += thermal_zone_outdoor_airflow_rate(zone)
    end

    # If the total OA requirement is zero do not add the DOAS system because the simulations will fail
    if tot_oa_req.zero?
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.Model.Model', "Not adding DOAS system for #{thermal_zones.size} zones because combined OA requirement for all zones is zero.")
      return false
    end
    OpenStudio.logFree(OpenStudio::Info, 'openstudio.Model.Model', "Adding DOAS system for #{thermal_zones.size} zones.")

    # create a DOAS air loop
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    if system_name.nil?
      air_loop.setName("#{thermal_zones.size} Zone DOAS")
    else
      air_loop.setName(system_name)
    end

    # set availability schedule
    if hvac_op_sch.nil?
      hvac_op_sch = model.alwaysOnDiscreteSchedule
    else
      hvac_op_sch = model_add_schedule(model, hvac_op_sch)
    end

    # DOAS design temperatures
    if clg_dsgn_sup_air_temp.nil?
      clg_dsgn_sup_air_temp_c = OpenStudio.convert(60.0, 'F', 'C').get
    else
      clg_dsgn_sup_air_temp_c = OpenStudio.convert(clg_dsgn_sup_air_temp, 'F', 'C').get
    end

    if htg_dsgn_sup_air_temp.nil?
      htg_dsgn_sup_air_temp_c = OpenStudio.convert(70.0, 'F', 'C').get
    else
      htg_dsgn_sup_air_temp_c = OpenStudio.convert(htg_dsgn_sup_air_temp, 'F', 'C').get
    end

    # modify system sizing properties
    sizing_system = air_loop.sizingSystem
    sizing_system.setTypeofLoadtoSizeOn('VentilationRequirement')
    sizing_system.setAllOutdoorAirinCooling(true)
    sizing_system.setAllOutdoorAirinHeating(true)
    # set minimum airflow ratio to 1.0 to avoid under-sizing heating coil
    if model.version < OpenStudio::VersionString.new('2.7.0')
      sizing_system.setMinimumSystemAirFlowRatio(1.0)
    else
      sizing_system.setCentralHeatingMaximumSystemAirFlowRatio(1.0)
    end
    sizing_system.setSizingOption('Coincident')
    sizing_system.setCentralCoolingDesignSupplyAirTemperature(clg_dsgn_sup_air_temp_c)
    sizing_system.setCentralHeatingDesignSupplyAirTemperature(htg_dsgn_sup_air_temp_c)

    if doas_type == 'DOASCV'
      supply_fan = create_fan_by_name(model,
                          'Constant_DOAS_Fan',
                          fan_name: 'DOAS Supply Fan',
                          end_use_subcategory: 'DOAS Fans')
    else # 'DOASVAV'
      supply_fan = create_fan_by_name(model,
                          'Variable_DOAS_Fan',
                          fan_name: 'DOAS Supply Fan',
                          end_use_subcategory: 'DOAS Fans')
    end
    supply_fan.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    supply_fan.setMaximumFlowRate(OpenStudio.convert(fan_maximum_flow_rate, 'cfm', 'm^3/s').get) unless fan_maximum_flow_rate.nil?
    unless heating_source == "WSHP" || cooling_source == "WSHP"
      supply_fan.addToNode(air_loop.supplyInletNode)
    end

    # create heating coil
    case heating_source
    when 'DX'
      # electric backup heating coil
      create_coil_heating_electric(model,
                                    air_loop_node: air_loop.supplyInletNode,
                                    name: "#{air_loop.name} Backup Htg Coil")
      # heat pump coil 
      create_coil_heating_dx_single_speed(model,
                                          air_loop_node: air_loop.supplyInletNode,
                                          name: "#{air_loop.name} Htg Coil",
                                          cop: heating_eff)
    when 'NaturalGas'
      # gas furnace
      create_coil_heating_gas(model,
                              air_loop_node: air_loop.supplyInletNode,
                              name: "#{air_loop.name} Gas Htg Coil",
                              efficiency: heating_eff)
    when 'Electricity'
      # electric backup heating coil
      create_coil_heating_electric(model,
                                  air_loop_node: air_loop.supplyInletNode,
                                  name: "#{air_loop.name} Electric Htg Coil",
                                  efficiency: heating_eff)
    when 'WSHP'
      if condenser_loop.nil?
        condenser_loop = model_get_or_add_heat_pump_loop(model)
      end
      htg_coil = create_coil_heating_water_to_air_heat_pump_equation_fit(model,
                                                              condenser_loop,
                                                              air_loop_node: nil,
                                                              name: "#{air_loop.name} Water-to-Air HP Htg Coil",
                                                              cop: heating_eff)
    end


    case cooling_source
    when 'DX'
      coil = create_coil_cooling_dx_two_speed(model,
                            air_loop_node: air_loop.supplyInletNode,
                            name: "#{air_loop.name} 2spd DX Clg Coil")

    when 'WSHP'
      if condenser_loop.nil?
        condenser_loop = model_get_or_add_heat_pump_loop(model)
      end
      clg_coil = create_coil_cooling_water_to_air_heat_pump_equation_fit(model,
                                                              condenser_loop,
                                                              air_loop_node: nil,
                                                              name: "#{air_loop.name} Water-to-Air HP Htg Coil",
                                                              cop: cooling_eff)
    end

    # construct unitary system for wshp
    if heating_source == "WSHP" || cooling_source == "WSHP"
      unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
      unitary_system.setName("#{air_loop.name} Unitary HP")
      unitary_system.setControlType("SetPoint")
      unitary_system.setSupplyFan(supply_fan) unless supply_fan.nil?
      unitary_system.setHeatingCoil(htg_coil) unless htg_coil.nil?
      unitary_system.setCoolingCoil(clg_coil) unless clg_coil.nil?
      unitary_system.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio.convert(40.0, 'F', 'C').get)
      unitary_system.setMaximumSupplyAirTemperature(htg_dsgn_sup_air_temp_c)
      unitary_system.setSupplyAirFlowRateMethodDuringCoolingOperation('SupplyAirFlowRate')
      unitary_system.setSupplyAirFlowRateMethodDuringHeatingOperation('SupplyAirFlowRate')
      unitary_system.setSupplyAirFlowRateMethodWhenNoCoolingorHeatingisRequired('SupplyAirFlowRate')
      unitary_system.setFanPlacement('BlowThrough')
      unitary_system.addToNode(air_loop.supplyInletNode)

      # specify control logic
      unitary_system.setAvailabilitySchedule(hvac_op_sch)
      if !doas_type == 'DOASCV'
        unitary_system.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
      else # constant volume operation
        unitary_system.setSupplyAirFanOperatingModeSchedule(hvac_op_sch)
      end
    end

    # minimum outdoor air schedule
    unless min_oa_sch.nil?
      min_oa_sch = model_add_schedule(model, min_oa_sch)
    end

    # minimum outdoor air fraction schedule
    if min_frac_oa_sch.nil?
      min_frac_oa_sch = model.alwaysOnDiscreteSchedule
    else
      min_frac_oa_sch = model_add_schedule(model, min_frac_oa_sch)
    end

    # create controller outdoor air
    controller_oa = OpenStudio::Model::ControllerOutdoorAir.new(model)
    controller_oa.setName("#{air_loop.name} Outdoor Air Controller")
    controller_oa.setEconomizerControlType(econo_ctrl_mthd)
    controller_oa.setMinimumLimitType('FixedMinimum')
    controller_oa.autosizeMinimumOutdoorAirFlowRate
    controller_oa.setMinimumOutdoorAirSchedule(min_oa_sch) unless min_oa_sch.nil?
    controller_oa.setMinimumFractionofOutdoorAirSchedule(min_frac_oa_sch)
    controller_oa.resetEconomizerMinimumLimitDryBulbTemperature
    controller_oa.resetEconomizerMaximumLimitDryBulbTemperature
    controller_oa.resetEconomizerMaximumLimitEnthalpy
    controller_oa.resetMaximumFractionofOutdoorAirSchedule
    controller_oa.setHeatRecoveryBypassControlType('BypassWhenWithinEconomizerLimits')
    controller_mech_vent = controller_oa.controllerMechanicalVentilation
    controller_mech_vent.setName("#{air_loop.name} Mechanical Ventilation Controller")
    controller_mech_vent.setDemandControlledVentilation(true) if demand_control_ventilation
    controller_mech_vent.setSystemOutdoorAirMethod('ZoneSum')

    # create outdoor air system
    oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller_oa)
    oa_system.setName("#{air_loop.name} OA System")
    oa_system.addToNode(air_loop.supplyInletNode)

    # create an exhaust fan
    if include_exhaust_fan
      if doas_type == 'DOASCV'
        exhaust_fan = create_fan_by_name(model,
                                'Constant_DOAS_Fan',
                                fan_name: 'DOAS Exhaust Fan',
                                end_use_subcategory: 'DOAS Fans')
      else # 'DOASVAV'
        exhaust_fan = create_fan_by_name(model,
                                'Variable_DOAS_Fan',
                                fan_name: 'DOAS Exhaust Fan',
                                end_use_subcategory: 'DOAS Fans')
      end
      # set pressure rise 1.0 inH2O lower than supply fan, 1.0 inH2O minimum
      exhaust_fan_pressure_rise = supply_fan.pressureRise - OpenStudio.convert(1.0, 'inH_{2}O', 'Pa').get
      exhaust_fan_pressure_rise = OpenStudio.convert(1.0, 'inH_{2}O', 'Pa').get if exhaust_fan_pressure_rise < OpenStudio.convert(1.0, 'inH_{2}O', 'Pa').get
      exhaust_fan.setPressureRise(exhaust_fan_pressure_rise)
      exhaust_fan.addToNode(air_loop.supplyInletNode)
    end

    # create a setpoint manager
    sat_oa_reset = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
    sat_oa_reset.setName("#{air_loop.name} SAT Reset")
    sat_oa_reset.setControlVariable('Temperature')
    sat_oa_reset.setSetpointatOutdoorLowTemperature(htg_dsgn_sup_air_temp_c)
    sat_oa_reset.setOutdoorLowTemperature(OpenStudio.convert(55.0, 'F', 'C').get)
    sat_oa_reset.setSetpointatOutdoorHighTemperature(clg_dsgn_sup_air_temp_c)
    sat_oa_reset.setOutdoorHighTemperature(OpenStudio.convert(70.0, 'F', 'C').get)
    sat_oa_reset.addToNode(air_loop.supplyOutletNode)

    # set air loop availability controls and night cycle manager, after oa system added
    air_loop.setAvailabilitySchedule(hvac_op_sch)
    air_loop.setNightCycleControlType('CycleOnAnyZoneFansOnly')

    # add thermal zones to airloop
    thermal_zones.each do |zone|
      # skip zones with no outdoor air flow rate
      unless thermal_zone_outdoor_airflow_rate(zone) > 0
        OpenStudio.logFree(OpenStudio::Debug, 'openstudio.Model.Model', "---#{zone.name} has no outdoor air flow rate and will not be added to #{air_loop.name}")
        next
      end

      OpenStudio.logFree(OpenStudio::Debug, 'openstudio.Model.Model', "---adding #{zone.name} to #{air_loop.name}")

      # make an air terminal for the zone
      if doas_type == 'DOASCV'
        air_terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      elsif doas_type == 'DOASVAVReheat'
        # Reheat coil
        if hot_water_loop.nil?
          rht_coil = create_coil_heating_electric(model, name: "#{zone.name} Electric Reheat Coil")
        else
          rht_coil = create_coil_heating_water(model, hot_water_loop, name: "#{zone.name} Reheat Coil")
        end
        # VAV reheat terminal
        air_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model, model.alwaysOnDiscreteSchedule, rht_coil)
        if model.version < OpenStudio::VersionString.new('3.0.1')
          air_terminal.setZoneMinimumAirFlowMethod('Constant')
        else
          air_terminal.setZoneMinimumAirFlowInputMethod('Constant')
        end
        air_terminal.setControlForOutdoorAir(true) if demand_control_ventilation
      else # 'DOASVAV'
        air_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVNoReheat.new(model, model.alwaysOnDiscreteSchedule)
        if model.version < OpenStudio::VersionString.new('3.0.1')
          air_terminal.setZoneMinimumAirFlowMethod('Constant')
        else
          air_terminal.setZoneMinimumAirFlowInputMethod('Constant')
        end
        air_terminal.setConstantMinimumAirFlowFraction(0.1)
        air_terminal.setControlForOutdoorAir(true) if demand_control_ventilation
      end
      air_terminal.setName("#{zone.name} Air Terminal")

      # attach new terminal to the zone and to the airloop
      air_loop.multiAddBranchForZone(zone, air_terminal.to_HVACComponent.get)

      # ensure the DOAS takes priority, so ventilation load is included when treated by other zonal systems
      # From EnergyPlus I/O reference:
      # "For situations where one or more equipment types has limited capacity or limited control capability, order the
      #  sequence so that the most controllable piece of equipment runs last. For example, with a dedicated outdoor air
      #  system (DOAS), the air terminal for the DOAS should be assigned Heating Sequence = 1 and Cooling Sequence = 1.
      #  Any other equipment should be assigned sequence 2 or higher so that it will see the net load after the DOAS air
      #  is added to the zone."
      zone.setCoolingPriority(air_terminal.to_ModelObject.get, 1)
      zone.setHeatingPriority(air_terminal.to_ModelObject.get, 1)

      # set the cooling and heating fraction to zero so that if DCV is enabled,
      # the system will lower the ventilation rate rather than trying to meet the heating or cooling load.
      if model.version < OpenStudio::VersionString.new('2.8.0')
        if demand_control_ventilation
          OpenStudio.logFree(OpenStudio::Error, 'openstudio.Model.Model', 'Unable to add DOAS with DCV to model because the setSequentialCoolingFraction method is not available in OpenStudio versions less than 2.8.0.')
        else
          OpenStudio.logFree(OpenStudio::Warn, 'openstudio.Model.Model', 'OpenStudio version is less than 2.8.0.  The DOAS system will not be able to have DCV if changed at a later date.')
        end
      else
        zone.setSequentialCoolingFraction(air_terminal.to_ModelObject.get, 0.0)
        zone.setSequentialHeatingFraction(air_terminal.to_ModelObject.get, 0.0)

        # if economizing, override to meet cooling load first with doas supply
        unless econo_ctrl_mthd == 'NoEconomizer'
          zone.setSequentialCoolingFraction(air_terminal.to_ModelObject.get, 1.0)
        end
      end
    

      # DOAS sizing
      sizing_zone = zone.sizingZone
      sizing_zone.setAccountforDedicatedOutdoorAirSystem(true)
      sizing_zone.setDedicatedOutdoorAirSystemControlStrategy(doas_control_strategy)
      sizing_zone.setDedicatedOutdoorAirLowSetpointTemperatureforDesign(clg_dsgn_sup_air_temp_c)
      sizing_zone.setDedicatedOutdoorAirHighSetpointTemperatureforDesign(htg_dsgn_sup_air_temp_c)
    end #thermal_zones.each

    return air_loop
  end

end
