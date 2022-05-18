# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddCentralIceStorage < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'


  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add Central Ice Storage'
  end

  # human readable description
  def description
    return 'Adds an ice storage tank and controls to existing chilled water loop for the purpose of thermal energy storage.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure allows users attach ice thermal energy storage (ITS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. '
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # thermal storage capacity (ton-hours)
    stor_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('stor_cap', true)
    stor_cap.setDisplayName("Thermal Storage Capacity (ton-hours)")
    stor_cap.setDescription("Energy capacity of Ice thermal storage in ton-hours")
    stor_cap.setDefaultValue(300)
    args << stor_cap

    # thermal storage objective: [full storage, partial storage]

    # daily charge hours - same as battery storage
    charge_hours = OpenStudio::Measure::OSArgument.makeStringArgument('charge_hours', true)
    charge_hours.setDisplayName("Ice Tank Charge Hours")
    charge_hours.setDescription("Enter daily times for battery charging, using 24-hour format. Applies every day in the full run period.")
    charge_hours.setDefaultValue('HH:MM - HH:MM')
    args << charge_hours

    # other possible arguments: 
    # storage configuration (series-upstream, series-downstream, parallel) - default series-downstream
    # chiller re-size (modify chiller capacity from baseline size)
    # 

    return args
  end

  def parse_time_range(range_string)
    # parses time range, e.g. "01:00 - 12:00" to array of hours ['01', '12'] and minutes ['00', '00']
    # if range 'wraps', e.g. "10:00 - 04:00", add last hour: ['04', '10', '24']
    hours = []
    minutes = []
    data = range_string.split(/[-:]/)
    data.each {|e| e.delete!(' ')}
    if data[2] > data[0]
      hours << data[0] << data[2]
      minutes << data[1] << data[3]
    else
      hours << data[2] << data[0] << 24
      minutes << data[3] << data[1] << 0
    end
    return hours, minutes
  end

  def os_times_from_string(range_string)
    # returns array of OS:Time objects from a time range string, e.g. "01:00 - 12:00"
    hours, minutes = parse_time_range(range_string)
    times = []
    hours.each_with_index do |h, i|
      times << OpenStudio::Time.new(0, h.to_i, minutes[i].to_i)
    end
    return times
  end

  def get_temperature(model)
    name = "TEMPERATURE"
    temperature_schedule_type_limits = model.getScheduleTypeLimitsByName(name)
    if temperature_schedule_type_limits.empty?
      temperature_schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      temperature_schedule_type_limits.setName(name)
      temperature_schedule_type_limits.setNumericType("Continuous")
      temperature_schedule_type_limits.setUnitType("Temperature")
      return temperature_schedule_type_limits
    else
      return temperature_schedule_type_limits.get
    end
  end

  def create_chiller_ice_setpoint_schedule(model, times, chw_temp, ice_temp)
    sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sch.setName("Chiller Ice Storage Setpoint Schedule")
    sch.setScheduleTypeLimits(get_temperature(model))
    d_day = sch.defaultDaySchedule
    times.each_with_index do |time, i|
      if times.size.even?
        # range within day, odd times are ice_temp
        i % 2 == 1 ? v = ice_temp : v = chw_temp
        d_day.addValue(time, v)
      else
        # range wraps day; even times are ice_temp
        i % 2 == 1 ? v = chw_temp : v = ice_temp
        d_day.addValue(time, v)
      end
    end
    return sch
  end

  def create_ice_setpoint_schedule(model, times, chw_temp)
    sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sch.setName("Ice Storage Setpoint Schedule")
    sch.setScheduleTypeLimits(get_temperature(model))
    d_day = sch.defaultDaySchedule
    off_temp = 99
    times.each_with_index do |time, i|
      if times.size.even?
        # range within day, odd times are 99
        i % 2 == 1 ? v = off_temp : v = chw_temp
        d_day.addValue(time,v)
      else 
        # range wraps day; even tiems are 99
        i % 2 == 1 ? v = chw_temp : v = off_temp
        d_day.addValue(time, v)
      end
    end
    return sch
  end

  def adjust_chiller_temp_limits(runner, chiller, ice_set)
    # set chiller lower temperature limit
    case chiller.iddObjectType.valueName
    when 'OS_Chiller_Electric_EIR'
      chiller = chiller.to_ChillerElectricEIR.get
      chiller.setLeavingChilledWaterLowerTemperatureLimit(ice_set)
    when 'OS_Chiller_Electric_Reformulated_EIR'
      chiller = chiller.to_ChillerElectricReformulatedEIR.get
      chiller.setLeavingChilledWaterLowerTemperatureLimit(ice_set)
    when 'OS_Chiller_Absorption'
      chiller.to_ChillerAbsorption.get.setChilledWaterOutletTemperatureLowerLimit(ice_set)
      return true
    when 'OS_Chiller_Absorption_Indirect'
      chiller.to_ChillerAbsorptionIndirect.get.setChilledWaterOutletTemperatureLowerLimit(ice_set)
      return true
    end
    runner.registerInfo("#{chiller.name.get} minimum setpoint temperature was adjusted to #{ice_set.round(2)} C.")

    # adjust curve minimum limits
    cap_adjust = false
    eir_adjust = false

    cap_ft = chiller.coolingCapacityFunctionOfTemperature
    min_x = cap_ft.minimumValueofx.to_f
    if min_x > ice_set
      cap_ft.setMinimumValueofx(ice_set)
      runner.registerWarning("The input range for curve: #{cap_ft.name} is too restrictive for use with ice charging. The curve limits have been extended to a lower limit of #{ice_set.round(2)} C for Leaving CHW Temp.")
      cap_adjust = true
    end
    eir_ft = chiller.electricInputToCoolingOutputRatioFunctionOfTemperature
    min_x = eir_ft.minimumValueofx.to_f
    if min_x > ice_set
      eir_ft.setMinimumValueofx(ice_set)
      runner.registerWarning("The input range for curve: #{eir_ft.name} is too restrictive for use with ice charging. The curve limits have been extended to a lower limit of #{ice_set.round(2)} C for Leaving CHW Temp.")
      eir_adjust = true
    end
    
    cap_derate = cap_ft.evaluate(ice_set, chiller.referenceEnteringCondenserFluidTemperature)
    eir_derate = eir_ft.evaluate(ice_set, chiller.referenceEnteringCondenserFluidTemperature)

    if cap_adjust
      runner.registerInfo("A curve extrapolation warning was registered for the chiller capacity as a function of temperature curve. " \
                           "At normal ice making temperatures, a chiller derate to 60-70% of nominal capacity is expected. With a ice "\
                           "temperature of #{ice_set.round(1)} C and condenser entering temperature of #{chiller.referenceEnteringCondenserFluidTemperature.round(1)} C, "\
                           "a capacity derate to #{(cap_derate * 100).round(1)}% is returned.")
    end
    if eir_adjust
      runner.registerInfo("A curve extrapolation warning was registered for the chiller EIR as a function of temperature curve. " \
      "With a ice temperature of #{ice_set.round(1)} C and condenser entering temperature of #{chiller.referenceEnteringCondenserFluidTemperature.round(1)} C, "\
      "a capacity derate to #{(eir_derate * 100).round(1)}% is returned.")
    end
    
    return true
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # get user arguments
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args
      runner.registerError("Could not find measure input arguments")
      return false
    end

    # assign user input to variables
    stor_cap = args['stor_cap']
    charge_hours = args['charge_hours']
    
    # check arguments for reasonableness 
    if stor_cap < 0
      runner.registerError("Storage Capacity cannot be less than 0 kW.")
      return false
    end

    # search model for chilled water loop 
    cooling_plantloops = []
    model.getPlantLoops.each do |plant|
      next if !plant.sizingPlant.loopType == "Cooling"
      # only take loops with chillers
      if plant.supplyComponents.any? {|comp| comp.iddObjectType.valueName.include?("Chiller")}
        cooling_plantloops << plant
      end
    end

    if cooling_plantloops.size == 0
      # end measure successfully (do nothing)
      runner.registerFinalCondition("No Chilled Water Loop found in model. No ice storage will be added.")
      return true
    elsif cooling_plantloops.size > 1
      runner.registerInfo("More than one chilled water loops found. Ice storage will be added to all loops.")
    end

    # create ice thermal storage
    cooling_plantloops.each do |plant|
      # get existing control
      chw_set = nil
      plant.loopTemperatureSetpointNode.setpointManagers.each do |spm|
        # CHW loop typically controlled by scheduled or OA reset SetpointManagers
        if spm.to_SetpointManagerScheduled.is_initialized
          spm = spm.to_SetpointManagerScheduled.get
          sch = spm.schedule
          result = OsLib_Schedules.getMinMaxAnnualProfileValue(model, sch)
          chw_set = result['min']
        elsif spm.to_SetpointManagerOutdoorAirReset.is_initialized
          spm = spm.to_SetpointManagerOutdoorAirReset.get
          chw_set = spm.setpointatOutdoorHighTemperature
        end
      end

      if !chw_set.nil?
        runner.registerInfo("Using existing chilled water setpoint temperature of #{chw_set.round(2)} C (#{OpenStudio.convert(chw_set, 'C','F').get.round(2)} F).")
      else
        runner.registerWarning("Could not determine the model's chilled water setpoint temperature. Defaulting to 7.22 C (45 F).")
        chw_set = 7.22
      end

      ice_set = -5.0 # 23F
    

      loop_name = plant.name.get
      # find chillers 
      chs = []
      plant.supplyComponents.each do |comp|
        if comp.iddObjectType.valueName.include?("Chiller")
          chs << comp.to_WaterToWaterComponent.get
        end
      end
  
      if chs.size == 0
        runner.registerWarning("No chillers found on #{plant}. Skipping")
      end
  
      # # create ice storage
      # ice = OpenStudio::Model::ThermalStorageIceDetailed.new(model)
      # ice.setName("#{loop_name} Ice Storage")
      # ice.setCapacity(OpenStudio.convert(stor_cap, 'ton*hr', 'GJ').get)
      
      # # for full storage, storage tank upstream
      # ice.addToNode(plant.supplySplitter.inletModelObject.get.to_Node.get)
  
      # adjust chiller curves
      chs.each do |chiller|
        # adjust chiller temp limits
        adjust_chiller_temp_limits(runner, chiller, ice_set)
        # create and set new chiller setpoints
        charge_sch = create_chiller_ice_setpoint_schedule(model, os_times_from_string(charge_hours), chw_set, ice_set)
        charge_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, charge_sch)
        charge_spm.addToNode(chiller.supplyOutletModelObject.get.to_Node.get)
        runner.registerInfo("Added new charge/discharge setpoint to #{chiller.name.get}.")
  
        # create ice storage
        ice = OpenStudio::Model::ThermalStorageIceDetailed.new(model)
        ice.setName("#{loop_name} Ice Storage")
        ice.setCapacity(OpenStudio.convert((stor_cap / chs.size), 'ton*hr', 'GJ').get)
        
        # for full storage, storage tank upstream
        ice.addToNode(chiller.supplyInletModelObject.get.to_Node.get)
  
        # create ice tank setpoint
        ice_set_sch = OpenStudio::Model::ScheduleRuleset.new(model, chw_set)
        ice_set_sch = create_ice_setpoint_schedule(model, os_times_from_string(charge_hours), chw_set)
        ice_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, ice_set_sch)
        ice_spm.addToNode(ice.outletModelObject.get.to_Node.get)
      end
  
      # adjust loop temps
      plant.setMinimumLoopTemperature(ice_set)
      runner.registerInfo("#{loop_name} minimum temperature was adjusted to #{ice_set.round(2)} C (#{OpenStudio.convert(ice_set,'C','F').get} F).")
  
      if plant.loadDistributionScheme != "SequentialLoad"
        plant.setLoadDistributionScheme('SequentialLoad')
        runner.registerInfo("#{plant.name.get} load distribution scheme set to 'SequentialLoad'.")
      end
  
      # adjust loop glycol solution to percentage 
      if plant.fluidType == "Water"
        plant.setFluidType("EthyleneGlycol")
        plant.setGlycolConcentration(25)
        runner.registerInfo("#{loop_name} working fluid changed to 25% ethylene glycol csolution.")
      end
  
      # adjust loop to two-way common pipe
      if plant.commonPipeSimulation != 'TwoWayCommonPipe'
        plant.setCommonPipeSimulation('TwoWayCommonPipe')
        runner.registerInfo("#{loop_name} common pipe simulation enabled.")
  
        # add setpointmanager to inlet of dmeand loop
        loop_set_node = plant.loopTemperatureSetpointNode
        loop_spms = loop_set_node.setpointManagers
        loop_spms.each do |spm|
          if spm.controlVariable == 'Temperature'
            demand_spm = spm.clone.to_SetpointManager.get
            demand_spm.addToNode(plant.demandInletNode)
            runner.registerInfo("Original loop temperature setpoint manager duplicated and added to demand loop inlet node.")
          end
        end
      end
  
    end

    add_ov = true
    if add_ov
      ov_names = [
        "Ice Thermal Storage Cooling Rate",
        "Ice Thermal Storage Change Fraction",
        "Ice Thermal Storage End Fraction",
        "Ice Thermal Storage On Coil Fraction",
        "Ice Thermal Storage Mass Flow Rate",
        "Ice Thermal Storage Bypass Mass Flow Rate",
        "Ice Thermal Storage Tank Mass Flow Rate",
        "Ice Thermal Storage Fluid Inlet Temperature",
        "Ice Thermal Storage Blended Outlet Temperature",
        "Ice Thermal Storage Tank Outlet Temperature",
        "Ice Thermal Storage Cooling Discharge Rate",
        "Ice Thermal Storage Cooling Discharge Energy",
        "Ice Thermal Storage Cooling Charge Rate",
        "Ice Thermal Storage Cooling Charge Energy",
        "Ice Thermal Storage Ancillary Electricity Rate",
        "Ice Thermal Storage Ancillary Electricity Energy"
      ]
      ovs = []
      ov_names.each do |n|
        ov = OpenStudio::Model::OutputVariable.new(n,model)
        ov.setReportingFrequency('Hourly')
        ovs << ov
      end
      runner.registerInfo("#{ovs.size} Output Variables Added.")
    end

    return true
  end
end

# register the measure to be used by the application
SCEAddCentralIceStorage.new.registerWithApplication
