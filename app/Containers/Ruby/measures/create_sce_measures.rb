
require 'openstudio'

# creates new OpenStudio measure template files

# sce measure info
# {
#   name: ,
#   className: ,
#   path: ,
#   taxonomy: ,
#   measureType: ,
#   description: ,
#   modelerDescription: ,
# }
measures_to_add = [
  # {
  #   name:"SCE Replace Existing DHW with Heat Pump Water Heater",
  #   className: "SCEReplaceExistingDHWWithHeatPumpWaterHeater",
  #   path: '/sce_replace_existing_dhw_with_heat_pump_water_heater',
  #   taxonomy: "Service Water Heating.Water Heating",
  #   measureType: "ModelMeasure",
  #   description: "Removes the existing domestic hot water heating source and replaces it with a heat pump water heater",
  #   modelerDescription: "The measure replaces the DHW heating source, without impacting DHW demand or temperatures. System performance will be set by Rated COP input; system curves will be 'typical' (default) and not guaranteed to reflect a particular model. The added HPWH will be auto sized by the simulation to provide the capacity needed to meet building demand. This measure may be used to simulate exclusively heat pump heated tanks, exclusively electrically heated tanks, or a combination of both."
  #  },
  # {
  #   name: "SCE Replace Building Heating Source with Electric Resistance",
  #   className: "SCEReplaceBuildingHeatingSourceWithElectricResistance",
  #   path: "/sce_replace_building_heating_source_with_electric_resistance",
  #   taxonomy: "HVAC.Heating",
  #   measureType: "ModelMeasure",
  #   description: "Replaces building fossil-fuel heating source with electric resistance heating.",
  #   modelerDescription: "The measure will determine the existing heating source and replace it with a similar system utilizing electric resistance heating in place of fossil-fuel. If the existing HVAC utilizes hydronic heating with a gas boiler, the measure will replace the gas boiler with electric resistance. Similarly, a gas furnace in an RTU will be replaced with electric heating.",
  # },
  # {
  #   name: "SCE Replace Gas Boiler with Electric Boiler",
  #   className: "SCEReplaceGasBoilerWithElectricBoiler",
  #   path: "/sce_replace_gas_boiler_with_electric_boiler",
  #   taxonomy: "HVAC.Heating",
  #   measureType: "ModelMeasure",
  #   description: "Replace existing gas or fuel boiler with electric boiler.",
  #   modelerDescription: "Replaces existing fossil-fuel hydronic heating source with electric resistance boiler with user-input efficiency. Replacement boiler will be controlled to the same leaving water temperature as the exisiting boiler, and auto-sized to meet the building load. If exisiting HVAC is not hydronic, the measure will do nothing.",
  # },
  # {
  #   name: "SCE Add Electric Storage",
  #   className: "SCEAddElectricStorage",
  #   path: "/sce_add_electric_storage",
  #   taxonomy: "Onsite Power Generation",
  #   measureType: "ModelMeasure",
  #   description: "Adds electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge",
  #   modelerDescription: "Adds simple electric storage in the model and offers two methods of controlling storage charging and discharging.
  #   Method 1.) Facility Demand Leveling – Storage will attempt to control the facility’s power demand drawn from the utility service to a prescribed level. When facility demand is below the target level the storage acts as a load on the grid and is charged. When facility demand is above the target level the storage is discharged to the grid to maintain the demand target.
  #   Method 2.) Scheduled Charging/Discharging Storage – Storage is scheduled to be charged and discharged according to specific charge and discharge schedules usually associated with time-of-day utility tariffs. User input will consist of daily start hour and end hour of charging and discharging periods.
  #   ",
  # },
  # {
  #   name: "SCE Add Photovoltaic with Electric Storage",
  #   className: "SCEAddPhotovoltaicWithElectricStorage",
  #   path: "/sce_add_photovoltaic_with_electric_storage",
  #   taxonomy: "Onsite Power Generation",
  #   measureType: "ModelMeasure",
  #   description: "Adds photovoltaic generation and electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge",
  #   modelerDescription: "Adds a photovoltaic array for electric generation and simple electric storage in the model. Offers two methods of controlling storage charging and discharging. The PV array will be located on the exterior of the building. A fixed cell efficiency will be assigned in the model. A fraction of the array’s surface area with active cells will also be assigned in the model to account for periods in which there is cloud cover or shading. The PVs inverter will be sized equal to the rated PV array power. The inverter will use a simple fixed efficiency.",
  # },
  # {
  #   name: "SCE Add Central Ice Storage",
  #   className: "SCEAddCentralIceStorage",
  #   path: "/sce_add_central_ice_storage",
  #   taxonomy: "HVAC.Energy Recovery",
  #   measureType: "ModelMeasure",
  #   description: "Adds an ice storage tank and controls to existing chilled water loop for the purpose of thermal energy storage.",
  #   modelerDescription: "The measure allows users attach ice thermal energy storage (ITS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. ",
  # },
  # {
  #   name: "SCE Add Chilled Water Storage",
  #   className: "SCEAddChilledWaterStorage",
  #   path: "/sce_add_chilled_water_storage",
  #   taxonomy: "HVAC.Energy Recovery",
  #   measureType: "ModelMeasure",
  #   description: "This measure adds a chilled water thermal energy storage tank to the model for the purpose load shifting.",
  #   modelerDescription: "The measure allows users attach chilled water thermal energy storage (CWTS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. ",
  # },
  # {
  #   name: "SCE Add Thermal Mass Preheat Cool",
  #   className: "SCEAddThermalMassPreheatCool",
  #   path: "/sce_add_thermal_mass_preheatcool",
  #   taxonomy: "HVAC.HVAC Controls",
  #   measureType: "ModelMeasure",
  #   description: "This measure adjusts building thermal mass and cooling and heating schedules by a user specified number of degrees and time period.",
  #   modelerDescription: "HVAC operation schedule will also be changed if the start time of the pre-cooling/heating is earlier than the default start value. An optional integer input is applied to each zones’ thermal capacitance, effectively modifying the mass of material in the building’s conditioned air volume. "
  # },
  # {
  #   name: "SCE Add Phase Change Materials",
  #   className: "SCEAddPhaseChangeMaterials",
  #   path: "/sce_add_phase_change_materials",
  #   taxonomy: "HVAC.HVAC Controls",
  #   measureType: "ModelMeasure",
  #   description: "Adds Phase Change Materials to all zones in the model and sets HVAC controls to allow materials to change state.",
  #   modelerDescription: "All zones in the model will receive PCM materials applied as InternalMass objects, representing ceiling tile applications such as Insolcorp Templok P-TESTM or Phase Change Energy Solutions’ BioPCM® products. Material properties will be defaulted to those applications, with freeze/melt temperatures tuned to the zones’ occupied cooling setpoint. The zones HVAC systems control will be adjusted to lower the nighttime temperature below the freezing point of the PCM material to allow it to absorb latent heat during the day.",
  # },
  {
    name: "SCE Add Phase Change Materials EP",
    className: "SCEAddPhaseChangeMaterialsEP",
    path: "/sce_add_phase_change_materials_ep",
    taxonomy: "HVAC.HVAC Controls",
    measureType: "EnergyPlusMeasure",
    description: "Adds Phase Change Materials to all zones in the model and sets HVAC controls to allow materials to change state.",
    modelerDescription: "All zones in the model will receive PCM materials applied as InternalMass objects, representing ceiling tile applications such as Insolcorp Templok P-TESTM or Phase Change Energy Solutions’ BioPCM® products. Material properties will be defaulted to those applications, with freeze/melt temperatures tuned to the zones’ occupied cooling setpoint. The zones HVAC systems control will be adjusted to lower the nighttime temperature below the freezing point of the PCM material to allow it to absorb latent heat during the day.",
  },
  # {
  #   name: "SCE Demand Response",
  #   className: "SCEDemandResponse",
  #   path: "/sce_demand_response",
  #   taxonomy: "Equipment.Equipment Controls",
  #   measureType: "EnergyPlusMeasure",
  #   description: "This measure adds control logic to the model to reduce the peak electrical power draw (demand) from the utility. Demand is managed in this model by turning down the lights and equipment and increasing the cooling setpoints throughout the facility.",
  #   modelerDescription: "The measure will create demand limiting objects that attempt to control electric equipment to the user-input target demand limit. The demand limiting control will attempt to limit facility demand to the target during the SCE TOU peak demand period defined in the SCE tariffs. Demand will be limited in priority order of exterior lights, interior lights, interior electric equipment, and HVAC thermostats. User will input the maximum limit fractions for each of the electric loads, and reset temperatures for the thermostats, which will be applied to all such loads and zones in the model."
  # },
  # {
  #   name: "SCE Add LCCA Parameters to Design Alternative",
  #   className: "SCEAddLCCAParameterstoDesignAlternative",
  #   path: "/sce_add_lcca_parameters_to_design_alternative",
  #   taxonomy: "Economics.Life Cycle Cost Analysis",
  #   measureType: "ModelMeasure",
  #   description: "The measure adds user-input life-cycle cost parameters for the entire design alternative.",
  #   modelerDescription: "The intent of the measure is to provide a simplified LCCA calculation approach for the entire building upgrade. Life-Cycle costs will be computed following the methodology in NIST Handbook 135, using the latest published use price escalation factors.",
  # }
]




def create_measure_files(measure_dir, measure_info)
  measure_info.each do |info|
    if File.exist?(measure_dir + info[:path])
      puts "Measure #{info[:name]} already exists"
      next
    end

    # create measure files
    measure = OpenStudio::BCLMeasure.new(info[:name], 
                              info[:className],
                              OpenStudio::Path.new(measure_dir + info[:path]),
                              info[:taxonomy],
                              OpenStudio::MeasureType.new(info[:measureType]),
                              info[:description],
                              info[:modelerDescription])

  end
end

base_path = File.dirname(__FILE__)
create_measure_files(base_path, measures_to_add)
