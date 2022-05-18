# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddElectricStorage < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add Electric Storage'
  end

  # human readable description
  def description
    return 'Adds electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Adds simple electric storage in the model and offers two methods of controlling storage charging and discharging.
    Method 1.) Facility Demand Leveling – Storage will attempt to control the facility’s power demand drawn from the utility service to a prescribed level. When facility demand is below the target level the storage acts as a load on the grid and is charged. When facility demand is above the target level the storage is discharged to the grid to maintain the demand target.
    Method 2.) Scheduled Charging/Discharging Storage – Storage is scheduled to be charged and discharged according to specific charge and discharge schedules usually associated with time-of-day utility tariffs. User input will consist of daily start hour and end hour of charging and discharging periods.
    '
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # storage operation scheme
    choices = ["Facility Demand Leveling", "Scheduled"]
    stor_op = OpenStudio::Measure::OSArgument.makeChoiceArgument("stor_op", choices, true)
    stor_op.setDisplayName("Battery Storage Control Mode")
    stor_op.setDescription("'Facility Demand Leveling' will attempt to control the facility's power demand dran from the utility service to a prescribed level. Scheduled will follow a user-input charging/discharging schedule.")
    stor_op.setDefaultValue('Facility Demand Leveling')
    args << stor_op 

    # utility demand target (kW)
    demand_target = OpenStudio::Measure::OSArgument.makeDoubleArgument('demand_target', true)
    demand_target.setDisplayName("Utility Demand Target (kW)")
    demand_target.setDescription("If Storage Control Mode = 'Facility Demand Leveling', this sets the target facility demand for discharge control - battery will discharge to maintain this demand level.")
    demand_target.setDefaultValue(100)
    args << demand_target

    # daily storage charge hours
    charge_hours = OpenStudio::Measure::OSArgument.makeStringArgument('charge_hours', true)
    charge_hours.setDisplayName("Battery Charge Hours")
    charge_hours.setDescription("If Storage Control Mode = 'Scheduled', enter daily times for battery charging, using 24-hour format. Applies every day in the full run period.")
    charge_hours.setDefaultValue('HH:MM - HH:MM')
    args << charge_hours

    # daily storage discharge hours
    # discharge_hours = OpenStudio::Measure::OSArgument.makeStringArgument('discharge_hours', false)
    # discharge_hours.setDisplayName("If Storage Control Mode = 'Scheduled', enter daily times for battery discharging, using 24-hour format.")
    # discharge_hours.setDescription("Applies every day in the full run period.")
    # discharge_hours.setDefaultValue('HH:MM - HH:MM')
    # args << discharge_hours

    # storage capacity in kW
    stor_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('stor_cap', true)
    stor_cap.setDisplayName("Battery Storage Capacity (kWh)")
    stor_cap.setDescription("Total energy storage capacity of battery. Default represents Tesla Powerwall 2.")
    stor_cap.setDefaultValue(14)
    args << stor_cap

    # charging/discharge power (KW)
    power = OpenStudio::Measure::OSArgument.makeDoubleArgument('power', true)
    power.setDisplayName("Battery Charge/Discharge Power (kW)")
    power.setDescription("Maximum rate at which electrical power can be charged/discharged from the battery. Default represents Tesla Powerwall 2.")
    power.setDefaultValue(5)
    args << power

    # roundtrip efficiency
    tot_eff = OpenStudio::Measure::OSArgument.makeDoubleArgument('tot_eff', true)
    tot_eff.setDisplayName("Nominal 'round-trip' (charge and discharge) energetic efficiency.")
    tot_eff.setDescription("Energetic efficiency from storing and drawing electricl energy from the battery. Values should be between 0.001 and 1.0. Model inputs for charing and discharging efficiency will be the square root of this total 'round-trip' value. Default value represents Tesla Powerwall 2.")
    tot_eff.setDefaultValue(0.9)
    args << tot_eff


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

  def get_fraction(model)
    # gets or creates Fractional Schedule Type Limits
    name = "FRACTION"
    fraction_schedule_type_limits = model.getScheduleTypeLimitsByName(name)
    if fraction_schedule_type_limits.empty?
      fraction_schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      fraction_schedule_type_limits.setName(name)
      fraction_schedule_type_limits.setNumericType("CONTINUOUS")
      fraction_schedule_type_limits.setUnitType("Dimensionless")
      fraction_schedule_type_limits.setLowerLimitValue(0.0)
      fraction_schedule_type_limits.setUpperLimitValue(1.0)
      return fraction_schedule_type_limits
    else
      return fraction_schedule_type_limits.get
    end
  end

  def create_charge_fraction_schedule(model, times)
    sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sch.setName("Battery Charge Fraction Schedule")
    sch.setScheduleTypeLimits(get_fraction(model))
    d_day = sch.defaultDaySchedule
    times.each_with_index do |time, i|
      if times.size.even?
        # range within day; odd times are 1
        i % 2 == 1 ? v = 1 : v = 0
        d_day.addValue(time, v)
      else
        # range wraps day; even times are 1
        i % 2 == 1 ? v = 0 : v = 1
        d_day.addValue(time, v)
      end
    end
    return sch
  end

  def invert_charge_frac_sch(model, sch)
    new_sch = sch.clone(model).to_ScheduleRuleset.get
    new_sch.setName("Battery Discharge Fraction Schedule")
    old_vals = sch.defaultDaySchedule.values
    old_times = sch.defaultDaySchedule.times
    old_times.each_with_index do |t, i|
      # XOR old value (0 or 1) to invert (1 or 0)
      new_sch.defaultDaySchedule.addValue(t, old_vals[i].to_i ^ 1)
    end
    return new_sch
  end


  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args
      runner.registerError("Could not find measure input arguments")
      return false
    end


    # assign user input to variables
    stor_op = args['stor_op']
    demand_target = args['demand_target']
    charge_hours = args['charge_hours']
    # discharge_hours = args['discharge_hours']
    stor_cap = args['stor_cap']
    power = args['power']
    tot_eff = args['tot_eff']

    # check arguments for reasonableness 
    check_eff_vals = {'min'=> 0.001, 'min_eq_bool' => true, 'max' => 1.0, 'max_eq_bool' => true, 'arg_array' => ['tot_eff']}
    eff_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, check_eff_vals)
    if !eff_vals_ok then return false end
    
    check_pos_vals = {'min'=> 0.0, 'min_eq_bool' => false, 'arg_array' => ['demand_target', 'stor_cap', 'power']}
    pos_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, check_pos_vals)
    if !pos_vals_ok then return false end

    if stor_op == "Scheduled" && charge_hours == "HH:MM - HH:MM"
      runner.registerError("Battery Storage Control set to 'Scheduled', but charge schedule argument not set. Set daily charge times to enable scheduled charging.")
      return false
    end


    # create battery object
    elcs = OpenStudio::Model::ElectricLoadCenterStorageSimple.new(model)
    elcs.setName("Battery Storage")
    elcs.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    elcs.setNominalDischargingEnergeticEfficiency(Math.sqrt(tot_eff))
    elcs.setNominalEnergeticEfficiencyforCharging(Math.sqrt(tot_eff))
    elcs.setMaximumPowerforDischarging(power * 1000)
    elcs.setMaximumPowerforCharging(power * 1000)
    elcs.setMaximumStorageCapacity(OpenStudio.convert(stor_cap, 'kWh', 'J').get)

    # create converter object
    elcsc = OpenStudio::Model::ElectricLoadCenterStorageConverter.new(model)
    elcsc.setName("Battery Storage Converter")
    elcsc.setSimpleFixedEfficiency(1.0)
    # elcsc.setEfficiencyFunctionofPowerCurve()
    # elcsc.setAncillaryPowerConsumedInStandby
    # elcsc.setRadiativeFraction
    # elcsc.setDesignMaximumContinuousInputPower()
    # elcsc.setThermalZone()

    # create load center distribution object
    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setName("Grid Battery Load Center")
    elcd.setElectricalBussType("AlternatingCurrentWithStorage")
    # inputs specific to control type
    case stor_op
    when 'Facility Demand Leveling'
      elcd.setStorageOperationScheme("FacilityDemandLeveling")
      elcd.setStorageControlUtilityDemandTarget(demand_target * 1000)
      elcd.setStorageControlUtilityDemandTargetFractionSchedule(model.alwaysOnDiscreteSchedule)
      elcd.setStorageDischargePowerFractionSchedule(model.alwaysOnDiscreteSchedule)
      elcd.setStorageChargePowerFractionSchedule(model.alwaysOnDiscreteSchedule)

    when 'Scheduled'
      # create charge/discharge schedules
      chg_sch = create_charge_fraction_schedule(model, os_times_from_string(charge_hours))
      dischg_sch = invert_charge_frac_sch(model, chg_sch)
      elcd.setStorageOperationScheme("TrackChargeDischargeSchedules")
      elcd.setStorageDischargePowerFractionSchedule(dischg_sch)
      elcd.setStorageChargePowerFractionSchedule(chg_sch)
    end
    # inputs common to both control types
    elcd.setDesignStorageControlChargePower(power * 1000)
    elcd.setDesignStorageControlDischargePower(power * 1000)
    elcd.setElectricalStorage(elcs)
    elcd.setStorageConverter(elcsc)
    
    add_ov = true
    if add_ov
      ov_names = [
        "Electric Storage Simple Charge State",
        "Electric Storage Charge Power",
        "Electric Storage Discharge Power",
        "Facility Total Produced Electricity Rate",
        "Facility Net Purchased Electricity Rate"
      ]

      # create new output variable objects
      ovs = []
      ov_names.each do |n|
        ov = OpenStudio::Model::OutputVariable.new(n, model)
        ov.setReportingFrequency('Hourly')
        ovs << ov
      end

      runner.registerInfo("#{ovs.size} Output Variables Added.")
    end

    return true
  end
end

# register the measure to be used by the application
SCEAddElectricStorage.new.registerWithApplication
