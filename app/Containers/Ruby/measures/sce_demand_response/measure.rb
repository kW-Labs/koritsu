# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEDemandResponse < OpenStudio::Measure::EnergyPlusMeasure
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Demand Response'
  end

  # human readable description
  def description
    return 'This measure adds control logic to the model to reduce the peak electrical power draw (demand) from the utility. Demand is managed in this model by turning down the lights and equipment and increasing the cooling setpoints throughout the facility.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will create demand limiting objects that attempt to control electric equipment to the user-input target demand limit. The demand limiting control will attempt to limit facility demand to the target during the SCE TOU peak demand period defined in the SCE tariffs. Demand will be limited in priority order of exterior lights, interior lights, interior electric equipment, and HVAC thermostats. User will input the maximum limit fractions for each of the electric loads, and reset temperatures for the thermostats, which will be applied to all such loads and zones in the model.'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # utility demand target (kW)
    demand_target = OpenStudio::Measure::OSArgument.makeDoubleArgument('demand_target', true)
    demand_target.setDisplayName("Target Demand Limit")
    demand_target.setDescription("Demand response controls will adjust building loads to attempt to maintain this demand level (kW).")
    demand_target.setDefaultValue(100)
    demand_target.setMinValue(0)
    args << demand_target

    ext_lt_lim_frac = OpenStudio::Measure::OSArgument.makeDoubleArgument('ext_lt_lim_frac', true)
    ext_lt_lim_frac.setDisplayName("Exterior Lighting Maximum Limit Fraction")
    ext_lt_lim_frac.setDescription("Fraction of building's exterior lighting power to be limited in a Demand Response event (value from 0 - 1).")
    ext_lt_lim_frac.setDefaultValue(1.0)
    args << ext_lt_lim_frac 

    int_lt_lim_frac = OpenStudio::Measure::OSArgument.makeDoubleArgument('int_lt_lim_frac', true)
    int_lt_lim_frac.setDisplayName("Interior Lighting Maximum Limit Fraction")
    int_lt_lim_frac.setDescription("Fraction of building's interior lighting power to be limited in a Demand Response event (value from 0 - 1).")
    int_lt_lim_frac.setDefaultValue(0.3)
    args << int_lt_lim_frac

    
    equip_lim_frac = OpenStudio::Measure::OSArgument.makeDoubleArgument('equip_lim_frac', true)
    equip_lim_frac.setDisplayName("Electric Equipment Maximum Limit Fraction")
    equip_lim_frac.setDescription("Fraction of building's electric equipment (plug and process load) power to be limited in a Demand Response event (value from 0 - 1).")
    equip_lim_frac.setDefaultValue(0.5)
    args << equip_lim_frac

    max_heat_reset = OpenStudio::Measure::OSArgument.makeDoubleArgument('max_heat_reset', true)
    max_heat_reset.setDisplayName("Minimum Temperature to Reset Thermostat Heating Setpoint")
    max_heat_reset.setDescription("During a Demand Response event, controls will attempt to meet demand limit by resetting thermostat setpoint temperature. This is the minimum temperature the heating setpoint will be allowed to be reset (F). An input of 0 will disallow setpoint adjustment for DR.")
    max_heat_reset.setDefaultValue(65.0)
    args << max_heat_reset

    max_cool_reset = OpenStudio::Measure::OSArgument.makeDoubleArgument('max_cool_reset', true)
    max_cool_reset.setDisplayName("Maximum Temperature to Reset Thermostat Cooling Setpoint")
    max_cool_reset.setDescription("During a Demand Response event, controls will attempt to meet demand limit by resetting thermostat setpoint temperature. This is the maximum temperature the cooling setpoint will be allowed to be reset (F). An input of 0 will disallow setpoint adjustment for DR.")
    max_cool_reset.setDefaultValue(78.0)
    args << max_cool_reset

    return args
  end

  
  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # get user arguments 

    args = OsLib_HelperMethods.createRunVariables(runner, nil, user_arguments, arguments(workspace))

    demand_target = args['demand_target']
    ext_lt_lim_frac = args['ext_lt_lim_frac']
    int_lt_lim_frac = args['int_lt_lim_frac']
    equip_lim_frac = args['equip_lim_frac']
    max_heat_reset = args['max_heat_reset']
    max_cool_reset = args['max_cool_reset']

    # demand_target = runner.getDoubleArgumentValue("demand_target",user_arguments)
    # ext_lt_lim_frac = runner.getDoubleArgumentValue("ext_lt_lim_frac", user_arguments)
    # int_lt_lim_frac = runner.getDoubleArgumentValue("int_lt_lim_frac", user_arguments)
    # equip_lim_frac = runner.getDoubleArgumentValue("equip_lim_frac", user_arguments)
    # max_heat_reset = runner.getDoubleArgumentValue("max_heat_reset", user_arguments)
    # max_cool_reset = runner.getDoubleArgumentValue("max_cool_reset", user_arguments)

    # check arguments for reasonableness
    if demand_target < 0
      runner.registerError('Entered demand target cannot be less than 0 kW.')
      return false
    end

    check_lim_vals = {'min'=> 0, 'min_eq_bool' => true, 'max'=> 1.0, 'max_eq_bool'=> true, 'arg_array' => ['ext_lt_lim_frac', 'int_lt_lim_frac', 'equip_lim_frac']}
    lim_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, check_lim_vals)
    if !lim_vals_ok
      return false
    end

    reset_heat = true
    reset_cool = true
    if max_heat_reset == 0
      reset_heat = false
      runner.registerInfo("Zero entered for Minimum Temperature to Reset THermostat Heating Setpoint. Heating thermostat reset won't be included as a DR strategy.")
    end
    
    if max_cool_reset == 0
      reset_cool = false
      runner.registerInfo("Zero entered for Maximum Temperature to Reset Thermostat Cooling Setpoint. Cooling thermostat reset won't be incuded as a DR strategy.")
    end


    string_objs = []
    
    # hash of object type -> object name
    dm_obj_info = {}

    # Demand Manager Exterior Lights
    ext_lt_names = []
    workspace.getObjectsByType("Exterior:Lights".to_IddObjectType).each do |obj|
      ext_lt_names << obj.getString(0).to_s
    end
    
    if ext_lt_names.size == 0
      runner.registerWarning("No Exterior Lights objects found in the model; Demand Response will not have Exterior Lighting power to adjust.")
    else
      string_objs << "
      DemandManager:ExteriorLights,
      Ext Lights Manager,      !- Name
      ,                        !- Availability Schedule Name
      FIXED,                   !- Limit Control
      60,                      !- Minimum Limit Duration {minutes}
      #{ext_lt_lim_frac},                     !- Maximum Limit Fraction
      ,                        !- Limit Step Change
      ALL,                     !- Selection Control
      ,                        !- Rotation Duration {minutes}
      #{ext_lt_names.join(",\n")};         !- Exterior Lights 1 Name
      "
      dm_obj_info["DemandManager:ExteriorLights"] = "Ext Lights Manager"
    end

    # Demand Manager Interior Lights
    int_lt_names = []
    workspace.getObjectsByType("Lights".to_IddObjectType).each do |obj|
      int_lt_names << obj.getString(0).to_s
    end

    if int_lt_names.size == 0
      runner.registerWarning("No Interior Lights objects found in the model; Demand Response will not have Interior Lighting power to adjust.")
    else
      string_objs << "
      DemandManager:Lights,
      Lights Manager,          !- Name
      ,                        !- Availability Schedule Name
      FIXED,                   !- Limit Control
      60,                      !- Minimum Limit Duration {minutes}
      #{int_lt_lim_frac},                     !- Maximum Limit Fraction
      ,                        !- Limit Step Change
      ALL,                     !- Selection Control
      ,                        !- Rotation Duration {minutes}
      #{int_lt_names.join(",\n")};    !- Lights 1 Name
      "
      dm_obj_info["DemandManager:Lights"] = "Lights Manager"
    end

    # Demand Manager Electric Equipment
    equip_names = []
    workspace.getObjectsByType("ElectricEquipment".to_IddObjectType).each do |obj|
      equip_names << obj.getString(0).to_s
    end

    if equip_names.size == 0
      runner.registerWarning("No Electric Equipment objects found in the model; Demand Reponse will not have Electric Equipment power to adjust.")
    else
      string_objs << "
      DemandManager:ElectricEquipment,
      Equip Manager,          !- Name
      ,                        !- Availability Schedule Name
      FIXED,                   !- Limit Control
      60,                      !- Minimum Limit Duration {minutes}
      #{equip_lim_frac},       !- Maximum Limit Fraction
      ,                        !- Limit Step Change
      ALL,                     !- Selection Control
      ,                        !- Rotation Duration {minutes}
      #{equip_names.join(",\n")};  !- Electric Equipment 1 Name
      "
      dm_obj_info["DemandManager:ElectricEquipment"] = "Equip Manager"
    end

    # Demand Manager Assignment List
    unless reset_heat || reset_cool
      tstat_names = []
      workspace.getObjectsByType("ZoneControl:Thermostat".to_IddObjectType).each do |obj|
        tstat_names << obj.getString(0).to_s
      end

      if tstat_names.size == 0
        runner.registerWarning("No Thermostats found in the model. Thermostat units won't be adjusted.")
      else
        string_objs << "
        DemandManager:Thermostats,
        Thermostats Manager,     !- Name
        ,                        !- Availability Schedule Name
        FIXED,                   !- Reset Control
        60,                      !- Minimum Reset Duration {minutes}
        #{OpenStudio.convert(max_heat_reset, 'F','C').get},                      !- Maximum Heating Setpoint Reset {C}
        #{OpenStudio.convert(max_cool_reset, 'F','C').get},                      !- Maximum Cooling Setpoint Reset {C}
        ,                        !- Reset Step Change
        ALL,                     !- Selection Control
        ,                        !- Rotation Duration {minutes}
        #{tstat_names.join(",\n")};  !- Thermostat 1 Name
        "
        dm_obj_info["DemandManager:Thermostats"] = "Thermostats Manager"
      end
    end

    # create limit schedule
    string_objs << "
    Schedule:Compact,
    Limit Schedule,          !- Name
    Any Number,              !- Schedule Type Limits Name
    THROUGH: 12/31,          !- Field 1
    FOR: AllDays,            !- Field 2
    UNTIL: 24:00,#{demand_target * 1000};    !- Field 3
    "

    # look for peak period schedule
    sch_name = ""
    sch = workspace.getObjectByTypeAndName("Schedule:Compact".to_IddObjectType, "SCE GS TOD Sch")
    if sch.is_initialized
      sch = sch.get
      sch_name = sch.getString(0).get
    end

    # DemandManager:AssignmentList
    string_objs << "
    DemandManagerAssignmentList,
    Demand Manager,          !- Name
    ElectricityNet:Facility,    !- Meter Name
    Limit Schedule,          !- Demand Limit Schedule Name
    1.0,                     !- Demand Limit Safety Fraction
    ,                        !- Billing Period Schedule Name
    #{sch_name},                        !- Peak Period Schedule Name
    15,                      !- Demand Window Length {minutes}
    SEQUENTIAL,              !- Demand Manager Priority
    #{dm_obj_info.to_a.join(",")};
    "

    # add all string objects
    runner.registerInfo("#{string_objs.size} Objects added to workspace")

    string_objs.each do |obj|
      idfObject = OpenStudio::IdfObject::load(obj)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    

    return true
  end
end

# register the measure to be used by the application
SCEDemandResponse.new.registerWithApplication
