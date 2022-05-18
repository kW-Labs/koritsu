# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'
require_relative 'resources/SCE_Hvac.rb'

# start the measure
class SCEReplaceGasBoilerWithElectricBoiler < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Replace Gas Boiler with Electric Boiler'
  end

  # human readable description
  def description
    return 'Replace existing gas or fuel boiler with electric boiler.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replaces existing fossil-fuel hydronic heating source with electric resistance boiler with user-input efficiency. Replacement boiler will be controlled to the same leaving water temperature as the exisiting boiler, and auto-sized to meet the building load. If exisiting HVAC is not hydronic, the measure will do nothing.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

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

    equip_changed = 0

    if heating_plantloops.size == 0
      runner.registerFinalCondition("No heating water loops with gas-consuming equipment were found in the model. No electric resistance boiler will be added.")
      return true
    else
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
              equip_changed += 1
            end
          when 'OS_Boiler_Steam'
            comp = comp.to_BoilerSteam.get
            if comp.fueltype == "NaturalGas"
              comp.setFuelType("Electricity")
              comp.setTheoreticalEfficiency(1.0)
              runner.registerInfo("Steam Boiler #{comp.name.get} changed from Natural Gas to Electricity fuel source.")
              equip_changed += 1
            end
          when 'OS_WaterHeater_Mixed'
            comp = comp.to_WaterHeaterMixed
            # check if heater actually has capacity
            if comp.heaterMaximumCapacity.empty? || comp.heaterMaximumCapacity.get != 0
              if comp.heaterFuelType == "NaturalGas"
                comp.setHeaterFuelType("Electricity")
                comp.setHeaterThermalEfficiency(1.0)
                runner.registerInfo("Water Heater Mixed #{comp.name.get} changed from Natural Gas fuel type to Electricity. Thermal Efficiency set to 1.0.")
                equip_changed += 1
              end
            end
          when 'OS_WaterHeater_Stratified'
            comp = comp.to_WaterHeaterStratified.get
            if comp.heaterMaximumCapacity.empty? || comp.heaterMaximumCapacity.get != 0
              if comp.fuelType == "NaturalGas"
                comp.setFuelType("Electricity")
                comp.setHeaterThermalEfficiency(1.0)
                runner.registerInfo("Water Heater Stratified #{comp.name.get} changed from Natural Gas fuel type to Electricity. Thermal Efficiency set to 1.0.")
                equip_changed += 1
              end
            end
          end
        end
      end
    end

    runner.registerFinalCondition("#{equip_changed} Plant Loop supply equipment with gas heating changed to use electric heat.")

        
    return true
  end
end

# register the measure to be used by the application
SCEReplaceGasBoilerWithElectricBoiler.new.registerWithApplication
