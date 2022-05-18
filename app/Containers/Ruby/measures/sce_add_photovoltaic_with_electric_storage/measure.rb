# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddPhotovoltaicWithElectricStorage < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add Photovoltaic with Electric Storage'
  end

  # human readable description
  def description
    return 'Adds photovoltaic generation and electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Adds a photovoltaic array for electric generation and simple electric storage in the model. Offers two methods of controlling storage charging and discharging. The PV array will be located on the exterior of the building. A fixed cell efficiency will be assigned in the model. A fraction of the array’s surface area with active cells will also be assigned in the model to account for periods in which there is cloud cover or shading. The PVs inverter will be sized equal to the rated PV array power. The inverter will use a simple fixed efficiency.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # pv array capacity (kW)
    pv_cap = OpenStudio::Measure::OSArgument::makeDoubleArgument('pv_cap', true)
    pv_cap.setDisplayName("Photovoltaic Array Capacity (kW)")
    pv_cap.setDescription("The total system generating capacity in kilowatts")
    pv_cap.setDefaultValue(100)
    args << pv_cap

    # pv module type [Standard, Premium, ThinFilm]
    mod_type_chs = ['Standard', 'Premium', 'ThinFilm']
    pv_mod_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('pv_mod_type', mod_type_chs, true)
    pv_mod_type.setDisplayName("PV Module Type")
    pv_mod_type.setDescription("PV system module type: <br>
                               'Standard': typical poly- or mono-crystalline modules with efficiencies from 14-17%.<br>
                               'Premium': monocrystalline silicon modules with anti-reflective coating and high efficiency (18-20%).<br>
                               'ThinFilm': thin film modules with low temperature coefficient and low efficiency ~11%.")
    pv_mod_type.setDefaultValue('Standard')
    args << pv_mod_type

    # pv position [ideal, specify]
    pos_chs = ['Ideal', 'Specified']
    pv_pos = OpenStudio::Measure::OSArgument::makeChoiceArgument('pv_pos', pos_chs, true)
    pv_pos.setDisplayName("PV Array Position Input Type")
    pv_pos.setDescription("Enter the input type for PV panel position: <br>
                          'Ideal' will calculate the panel tilt based on project (weather file) latitude.<br>
                          'Specified' will use tilt value entered in 'Panel Tilt' argument below.")
    pv_pos.setDefaultValue('Ideal')
    args << pv_pos

    # pv tilt angle
    tilt = OpenStudio::Measure::OSArgument::makeDoubleArgument('tilt', true)
    tilt.setDisplayName("PV Panel Tilt Angle (deg)")
    tilt.setDescription("Angle that the panel is tilted from horizontal (0\u00B0 - horizontal; 90\u00B0 - vertical).<br>Note: this argument only used if 'PV Array Position Input Type' = 'Specified'.")
    tilt.setDefaultValue(0.0)
    args << tilt

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

  def optimal_fixed_tilt(latitude)
    # returns the 'optimal' fixed PV array tilt based on latitude
    # from: https://doi.org/10.1016/j.solener.2018.04.030
    if latitude > 0
      # northern hemisphere
      t = 1.3793 + latitude * (1.2011 + latitude * (-0.014404 + latitude * 0.000080509))
    else
      t = -0.41657 + latitude * (1.4216 + latitude * (0.024051 + latitude * 0.00021828))
    end
    # To allow for rain to naturally clean panels, optimal tilt angles between −10 and +10° latitude
    # are usually limited to either −10° (for negative values) or +10° (for positive values)
    if t.abs < 10.0
      t = 10.0 * (t/t.abs)
    end
    return t
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

    # get user arguments
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args
      runner.registerError("Could not find measure input arguments")
      return false
    end

    # assign user inputs to variables
    pv_cap = args['pv_cap']
    pv_mod_type = args['pv_mod_type']
    pv_pos = args['pv_pos']
    tilt = args['tilt']
    stor_op = args['stor_op']
    demand_target = args['demand_target']
    charge_hours = args['charge_hours']
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

    # pvwatts defaults
    array_type = 'FixedRoofMounted'
    system_losses = 0.1
    azimuth_angle = 180.0

    # create generator: PV watts
    pv_cap_w = pv_cap * 1000
    gpv = OpenStudio::Model::GeneratorPVWatts.new(model, pv_cap_w)
    gpv.setName("Solar PV System")
    gpv.setModuleType(pv_mod_type)
    gpv.setArrayType(array_type)
    gpv.setSystemLosses(system_losses)
    gpv.setAzimuthAngle(azimuth_angle)
    case pv_pos
    when 'Ideal'
      # check if site is populated
      if model.getSite.latitude == model.getSite.longitude && model.getSite.latitude == 0.0
        # check weatherfile
        if model.getWeatherFile.latitude == model.getWeatherFile.longitude
          runner.registerInfo("Could not determine site latitude from Site or WeatherFile objects. Make sure a building location has been defined in the input file. Defaulting to latitude of 45\u00B0N.")
          latitude = 45.0
        else
          latitude = model.getWeatherFile.latitude
        end
      else
        latitude = model.getSite.latitude
      end
      runner.registerInfo("For a building located at #{latitude}\u00B0 latitude, the 'ideal' panel fixed tilt angle of #{optimal_fixed_tilt(latitude).round(2)}\u00B0 will be applied.")
      tilt = optimal_fixed_tilt(latitude)
    when 'Specified'
      if tilt == 0.0
        runner.registerWarning("PV Array Position input type entered as 'Specified', but panel tilt entered as 0\u00B0 (horizontal). Panel tilt will be set to 10\u00B0 to allow rain to clean panels.")
      elsif tilt.abs < 10.0
        runner.registerWarning("Entered PV tilt less than +/-10\u00B0 from horizontal. To allow rainfall to clean panels, tilt will be set to +/-10\u00B0.")
        tilt = 10.0 * (tilt/tilt.abs)
      end
    end
    gpv.setTiltAngle(tilt)
    
    # create inverter
    pv_inv = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
    pv_inv.setName("Solar PV System Inverter")
    pv_inv.setDCToACSizeRatio(1.10)
    pv_inv.setInverterEfficiency(0.96)

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
    elcd.setName("PV Battery Load Center")
    elcd.setElectricalBussType("DirectCurrentWithInverterDCStorage")
    elcd.setGeneratorOperationSchemeType("Baseload")
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
    elcd.setInverter(pv_inv)
    elcd.addGenerator(gpv)

    add_ov = true
    if add_ov
      ov_names = [
        "Electric Storage Simple Charge State",
        "Electric Storage Charge Power",
        "Electric Storage Discharge Power",
        "Facility Total Produced Electricity Rate",
        "Facility Net Purchased Electricity Rate",
        'Facility Total Building Electricity Demand Rate',
        'Facility Total HVAC Electricity Demand Rate',
        "Facility Total Electricity Demand Rate",
        'Inverter DC Input Electricity Rate',
        'Inverter AC Output Electricity Rate',
        'Generator Produced DC Electricity Rate'
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
SCEAddPhotovoltaicWithElectricStorage.new.registerWithApplication
