# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddThermalMassPreheatCool < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_schedules'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add Thermal Mass Preheat Cool'
  end

  # human readable description
  def description
    return 'This measure adjusts building thermal mass and cooling and heating schedules by a user specified number of degrees and time period.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'HVAC operation schedule will also be changed if the start time of the pre-cooling/heating is earlier than the default start value. An optional integer input is applied to each zones’ thermal capacitance, effectively modifying the mass of material in the building’s conditioned air volume. '
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # precool thermostat temperature adjustment
    cool_temp_shift = OpenStudio::Measure::OSArgument.makeDoubleArgument('cool_temp_shift', true)
    cool_temp_shift.setDisplayName("Precool Temperature Adjustment")
    cool_temp_shift.setDescription("Number of degrees Farenheight to offset the existing cooling setback temperature for pre-cooling.")
    cool_temp_shift.setDefaultValue(3.0)
    args << cool_temp_shift

    # preheat thermostat temperature adjustment
    heat_temp_shift = OpenStudio::Measure::OSArgument.makeDoubleArgument('heat_temp_shift', true)
    heat_temp_shift.setDisplayName("Preheat Temperature Adjustment")
    heat_temp_shift.setDescription("Number of degrees Farenheight to ofset the existing heating setback temperature for pre-heating.")
    heat_temp_shift.setDefaultValue(2.0)
    args << heat_temp_shift

    # precool/heat start hour adjustment
    start_hour_shift = OpenStudio::Measure::OSArgument.makeDoubleArgument('start_hour_shift', true)
    start_hour_shift.setDisplayName("HVAC Operation Start Time Shift")
    start_hour_shift.setDescription("Enter number of hours to advance the HVAC system start time via thermostat schedule adjustment.")
    start_hour_shift.setDefaultValue(1.0)
    args << start_hour_shift

    # # precool/heat end hour adjustment
    # stop_hour_shift = OpenStudio::Measure::OSARgument.makeDoubleArgument('stop_hour_shift',true)
    # stop_hour_shift.setDisplayName("HVAC Operation Stop Time Shift")
    # stop_hour_shift.setDescription("Enter number of hours to extend the HVAC operation time via thermostate schedule adjustment.")
    # stop_hour_shift.setDefaultValue(1.0)
    # args << stop_hour_shift

    # thermal capacitance multiplier
    tcap = OpenStudio::Measure::OSArgument.makeDoubleArgument('tcap',true)
    tcap.setDisplayName("Thermal Capacitance Multiplier")
    tcap.setDescription("This value adjusts the effective thermal storage capacity of the zones in the model, approximating and increase/decrease in thermal mass. Values above 1.0 will increase capacitance; values from 0-1 will decrease it.")
    tcap.setDefaultValue(1.0)
    args << tcap

    return args
  end

  def schedule_min_max_values(schedule)
    # returns min/max values of a given schedule
    std = Standard.build("90.1-2004")
    result = nil
    if schedule.to_ScheduleRuleset.is_initialized
      result = std.schedule_ruleset_annual_min_max_value(schedule.to_ScheduleRuleset.get)
    elsif schedule.to_ScheduleConstant.is_initialized
      result = std.schedule_constant_annual_min_max_value(schedule.to_ScheduleConstant.get)
    elsif schedule.to_ScheduleCompact.is_initialized
      result = std.schedule_compact_annual_min_max_value(schedule.to_ScheduleCompact.get)
    end
    return result
  end

  def tstat_info(model)
    # returns an array of hashes with information on all thermostats used in the model:
    # heat_sch: = heating schedule (ScheduleRuleset)
    # heat_min_temp: minimum heating (setback) temp (C)
    # heat_max_temp: max heating (setpoint) temp (C)
    # cool_sch: = cooling schedule (ScheduleRuleset)
    # cool_min_temp: minimum cooling (setpoint) temp (C)
    # cool_max_temp: maximum cooling (setpoint) temp (C)
    # zone_names: = list of zone names with tstat applied (Array)

    all_info = []
    model.getThermostatSetpointDualSetpoints.each do |stat|
      puts stat.name.get
      if stat.heatingSetpointTemperatureSchedule.is_initialized
        htg_sch = stat.heatingSetpointTemperatureSchedule.get
      end
      if stat.coolingSetpointTemperatureSchedule.is_initialized
        clg_sch = stat.coolingSetpointTemperatureSchedule.get
      end
      if stat.thermalZone.is_initialized
        zone = stat.thermalZone.get
      end
  
      next if htg_sch.nil? && clg_sch.nil?

      result = all_info.select{|h| h[:heat_sch] == htg_sch && h[:cool_sch] == clg_sch}
      if result.empty?
        all_info << {heat_sch: htg_sch, cool_sch: clg_sch, zone_names: [zone.name.get]}
      else
        entry = result.first
        entry[:zone_names] << zone.name.get
      end
    end

    all_info.each do |h|
      heat_temps = schedule_min_max_values(h[:heat_sch])
      h[:heat_min_temp] = heat_temps['min']
      h[:heat_max_temp] = heat_temps['max']
      cool_temps = schedule_min_max_values(h[:cool_sch])
      h[:cool_min_temp] = cool_temps['min']
      h[:cool_max_temp] = cool_temps['max']
    end
  
    return all_info
  end

  def string_to_os_time(str)
    # str = "18:00:00"
    hms = str.split(":").map{|i| i.to_i}
    if !hms.size == 3
      puts "WARNING: String in string_to_os_time not formatted as expected"
    end
  
    os_time = OpenStudio::Time.new(0,hms[0], hms[1], hms[2])
    return os_time
  end

  def adjust_tstat_schedule(schedule, temp_shift, start_shift)
    if schedule.to_ScheduleRuleset.is_initialized
      schedule = schedule.to_ScheduleRuleset.get
    else 
      return false
    end

    # collect default day schedule and ScheduleRules
    days = []
    days << schedule.defaultDaySchedule
    schedule.scheduleRules.each {|s| days << s.daySchedule}

    days.each do |day|
      timevals = []
      day.times.each_with_index {|t,i| timevals << [t, day.values[i]]}
      
      if timevals.size > 1
        occ_start_time = timevals[0][0]
        start_shift_os = string_to_os_time("#{start_shift}:00:00")
        shifted_start = occ_start_time - start_shift_os
        setback_t = timevals[0][1]
        shifted_setback = setback_t + temp_shift
      else
        # schedule does not set back
        next
      end

      day.removeValue(occ_start_time)
      day.addValue(shifted_start, setback_t)
      day.addValue(occ_start_time, shifted_setback)
    end

    return schedule
  end


  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign user input to variables 
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end
    
    # check expected values of double arguments
    time_vals = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min'=> -4.0, 'max'=> 4.0, 'min_eq_bool'=> true, 'max_eq_bool'=> true, 'arg_array'=>['start_hour_shift'])


    # convert temps to SI
    cool_temp_shift_si = OpenStudio.convert(args['cool_temp_shift'],"R","K").get
    heat_temp_shift_si = OpenStudio.convert(args['heat_temp_shift'],"R","K").get

    # get info for all thermostat schedules
    tstat_info = []
    model.getThermostatSetpointDualSetpoints.each do |stat|
      
      if stat.heatingSetpointTemperatureSchedule.is_initialized
        htg_sch = stat.heatingSetpointTemperatureSchedule.get
      end
      if stat.coolingSetpointTemperatureSchedule.is_initialized
        clg_sch = stat.coolingSetpointTemperatureSchedule.get
      end
      if stat.thermalZone.is_initialized
        zone = stat.thermalZone.get
      end
  
      if htg_sch.nil? && clg_sch.nil?
        runner.registerInfo("Thermostate #{stat.name.get} does not have cooling or heating setpoint schedules assigned. Skipping.")
        next
      end

      if zone.nil? 
        runner.registerInfo("THermostat #{stat.name.get} is not assigned to any thermal zone in model. Skipping.")
        next
      end

      result = tstat_info.select{|h| h[:heat_sch] == htg_sch && h[:cool_sch] == clg_sch}
      if result.empty?
        tstat_info << {heat_sch: htg_sch, cool_sch: clg_sch, zone_names: [zone.name.get]}
      else
        entry = result.first
        entry[:zone_names] << zone.name.get
      end
    end

    # set thermostat schedule min/max values
    tstat_info.each do |h|
      heat_temps = schedule_min_max_values(h[:heat_sch])
      h[:heat_min_temp] = heat_temps['min']
      h[:heat_max_temp] = heat_temps['max']
      cool_temps = schedule_min_max_values(h[:cool_sch])
      h[:cool_min_temp] = cool_temps['min']
      h[:cool_max_temp] = cool_temps['max']
    end

    # adjust schedules

    adjusted = 0
    tstat_info.each do |data|
      deadband = data[:cool_min_temp] - data[:heat_max_temp]
      deaband_f = OpenStudio.convert(deadband,"C","F").get

      # check input temp values against thermostat deadband
      unocc_cool_f = OpenStudio.convert(data[:cool_max_temp],"C","F").get
      occ_cool_f = OpenStudio.convert(data[:cool_min_temp],"C","F").get
      unocc_heat_f = OpenStudio.convert(data[:heat_min_temp],"C","F").get
      occ_heat_f = OpenStudio.convert(data[:heat_max_temp],"C","F").get

      # check that temperature adjustments aren't too extreme
      if (unocc_cool_f - args['cool_temp_shift']) < occ_heat_f
        runner.registerWarning("The entered value for Precool Temperature Adjustment will set the unoccupied cooling setpoint to #{(unocc_cool_f - args['cool_temp_shift']).round(1)}F, which is less than the occupied heating setpoint of #{occ_heat_f.round(1)}F, which may excessively increase heating energy.")
      elsif (unocc_cool_f - args['cool_temp_shift']) < unocc_heat_f
        runner.registerError("The entered value for Precool Temperature Adjustment will set the unoccupied cooling setpoint to #{(unocc_cool_f - args['cool_temp_shift']).round(1)}F, which is less than the unoccupied heating setpoint of #{unocc_heat_f.round(1)}F, which is not a valid control condition. Revise inputs and try again")
        return false
      end

      if (unocc_heat_f + args['heat_temp_shift']) > occ_cool_f
        runner.registerWarning("The entered value for Preheat Temperature Adjustment will set the unoccupied heating setpoint to #{(unocc_heat_f + args['heat_temp_shift']).round(1)}F, which is greater than the occupied cooling setpoints of #{occ_cool_f.round(1)}F, which may excessively increase cooling energy.")
      elsif (unocc_heat_f + args['heat_temp_shift']) > unocc_cool_f
        runner.registerWarning("The entered value for Preheat Temperature Adjustment will set the uoccupied heating setpoint to #{(unocc_heat_f + args['heat_temp_shift']).round(1)}F, which is greater than the unoccupied cooling setpoint of #{unocc_cool_f.round(1)}F, which is not a valid control condition. Revise inputs and try again.")
        return false
      end


      # adjust heating schedule
      sch = adjust_tstat_schedule(data[:heat_sch], heat_temp_shift_si, args['start_hour_shift'])
      if !sch
        runner.registerWarning("Error encountered in adjusting #{data[:heat_sch].name.get}. Schedule may be of incorrect type or does not set back. #{data[:zone_names].size} Thermal Zones assigned this schedule. Measure continues.")
      else 
        adjusted += 1
      end

      # adjust cooling schedule
      sch = adjust_tstat_schedule(data[:cool_sch], -cool_temp_shift_si, args['start_hour_shift'])
      if !sch
        runner.registerWarning("Error encountered in adjusting #{data[:cool_sch].name.get}. Schedule may be of incorrect type or does not set back. #{data[:zone_names].size} Thermal Zones assigned this schedule. Measure continues.")
      else
        adjusted += 1
      end

    end
    
    # adjust thermal capacitance
    cap = args['tcap']
    runner.registerInfo("Adjusting Zone Thermal Capacitance Multiplier to #{cap}")
    model.getZoneCapacitanceMultiplierResearchSpecial.setTemperatureCapacityMultiplier(cap)

    runner.registerFinalCondition("#{adjusted} Thermostat setpoint schedules adjusted to precool/preheat, and Zone thermal mass adjusted by a #{cap}x multiplier.")
    return true
  end
end

# register the measure to be used by the application
SCEAddThermalMassPreheatCool.new.registerWithApplication
