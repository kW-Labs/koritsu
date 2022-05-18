# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'
require_relative 'resources/SCE_Hvac.rb'

# start the measure
class SCEReplaceBuildingHeatingSourceWithElectricResistance < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Replace Building Heating Source with Electric Resistance'
  end

  # human readable description
  def description
    return 'Replaces building fossil-fuel heating source with electric resistance heating.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will determine the existing heating source and replace it with a similar system utilizing electric resistance heating in place of fossil-fuel. If the existing HVAC utilizes hydronic heating with a gas boiler, the measure will replace the gas boiler with electric resistance. Similarly, a gas furnace in an RTU will be replaced with electric heating.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # no arguments

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # find any gas HVAC heating source and turn it electric
    all_fuels = []
    model.getPlantLoops.each {|pl| all_fuels << model.plant_loop_heating_fuels(pl)}
    model.getThermalZones.each do |zn| 
      all_fuels << model.zone_airloop_heating_fuels(zn)
      all_fuels << model.zone_equipment_heating_fuels(zn)
    end
  
    # existing heating source can be
    # plant - boilers, air-source heat pump
    heating_plantloops = []
    model.getPlantLoops.each do |plant|
      next if plant.demandComponents.any?{|comp| comp.to_WaterUseConnections.is_initialized}
      next if !plant.sizingPlant.loopType == "Heating"
      heating_fuels = model.plant_loop_heating_fuels(plant)
      if heating_fuels.include? "NaturalGas"
        heating_plantloops << plant
      else
        runner.registerInfo("No Gas heating found for plant loops in model")
      end
    end

    heating_airloops = []
    heating_zoneequip = []

    # GAS_COILS = ['OS_Coil_Heating_Gas', 'OS_Coil_Heating_Gas_MultiStage']
    # UNITARY_TYPES = ['OS_AirLoopHVAC_UnitaryHeatCool_VAVChangeoverBypass', 'OS_AirLoopHVAC_UnitaryHeatPump_AirToAir', 'OS_AirLoopHVAC_UnitaryHeatPump_AirToAir_MultiSpeed', 'OS_AirLoopHVAC_UnitarySystem']

    model.getThermalZones.each do |zone|
      # air systems
      air_loop_heating_fuels = model.zone_airloop_heating_fuels(zone)
      if air_loop_heating_fuels.include? "NaturalGas"
        if zone.airLoopHVAC.is_initialized
          if !heating_airloops.include? zone.airLoopHVAC.get
            heating_airloops << zone.airLoopHVAC.get
          end
        end
      end
      # zone systems
      heating_zoneequip << model.zone_gas_heating_equipment(zone)
      # heating_zoneequip.flatten!.each {|e| puts e.iddObjectType.valueName}
    end
    
    # replace plant gas equipment
    if heating_plantloops.size > 0
      heating_plantloops.each do |plant_loop|
        plant_loop.supplyComponents.each do |comp|
          # find gas component and switch heating type
          comp_type = comp.iddObjectType.valueName.to_s
          case comp_type
          when 'OS_Boiler_HotWater'
            comp = comp.to_BoilerHotWater.get
            if comp.fuelType == "NaturalGas"
              comp.setFuelType("Electricity")
              comp.setNominalThermalEfficiency(1.0)
              comp.resetNormalizedBoilerEfficiencyCurve
              runner.registerInfo("Hot Water Boiler #{comp.name.get} changed from Natural Gas to Electricity and thermal efficiency set to constant 1.0.")
            end
          when 'OS_Boiler_Steam'
            comp = comp.to_BoilerSteam.get
            if comp.fueltype == "NaturalGas"
              comp.setFuelType("Electricity")
              comp.setTheoreticalEfficiency(1.0)
              runner.registerInfo("Steam Boiler #{comp.name.get} changed from Natural Gas to Electricity fuel source.")
            end
          when 'OS_WaterHeater_Mixed'
            comp = comp.to_WaterHeaterMixed
            # check if heater actually has capacity
            if comp.heaterMaximumCapacity.empty? || comp.heaterMaximumCapacity.get != 0
              if comp.heaterFuelType == "NaturalGas"
                comp.setHeaterFuelType("Electricity")
                comp.setHeaterThermalEfficiency(1.0)
                runner.registerInfo("Water Heater Mixed #{comp.name.get} changed from Natural Gas fuel type to Electricity. Thermal Efficiency set to 1.0.")
              end
            end
          when 'OS_WaterHeater_Stratified'
            comp = comp.to_WaterHeaterStratified.get
            if comp.heaterMaximumCapacity.empty? || comp.heaterMaximumCapacity.get != 0
              if comp.fuelType == "NaturalGas"
                comp.setFuelType("Electricity")
                comp.setHeaterThermalEfficiency(1.0)
                runner.registerInfo("Water Heater Stratified #{comp.name.get} changed from Natural Gas fuel type to Electricity. Thermal Efficiency set to 1.0.")
              end
            end
          when 'OS_HeatExchanger_FluidToFluid'
            # shouldn't have to do anything here, since the source loop would be in the group
          end
        end
      end
    end

    # get all gas coils and replace them in their air loops or parent components
    all_gas_coils = []
    model.getCoilHeatingGass.each {|c| all_gas_coils << c}
    model.getCoilHeatingGasMultiStages.each {|c| all_gas_coils << c}
    all_gas_coils.sort.each do |c|
      name = c.name.get
      if model.replace_gas_coil_with_electric(c)
        runner.registerInfo("Replaced #{name} with electric heating coil")
      else
        runner.registerWarning("Could not replace #{name}")
      end
    end

    # cover special zonehvac cases
    heating_zoneequip.flatten!.each do |equip|
      obj_type = equip.iddObjectType.valueName.to_s
      case obj_type
      when 'OS_ZoneHVAC_HighTemperatureRadiant'
        equip.setFuelType("Electricity")
        runner.registerInfo("#{equip.name.get} Fuel type set to Electricity")
      end
    end

    # TODO: Supplemental heating coils
    runner.registerFinalCondition("Model gas heating sources have been replaced with electric resistance.")

    return true
  end
end

# register the measure to be used by the application
SCEReplaceBuildingHeatingSourceWithElectricResistance.new.registerWithApplication
