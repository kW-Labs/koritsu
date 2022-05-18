# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEReplaceExistingDHWWithHeatPumpWaterHeater < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'
  # resource file modules
  include OsLib_HelperMethods
  include OsLib_ModelGeneration
  include OsLib_Schedules

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Replace Existing DHW with Heat Pump Water Heater'
  end

  # human readable description
  def description
    return 'Removes the existing domestic hot water heating source and replaces it with a heat pump water heater'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure replaces the DHW heating source, without impacting DHW demand or temperatures. System performance will be set by Rated COP input; system curves will be \'typical\' (default) and not guaranteed to reflect a particular model. The added HPWH will be auto sized by the simulation to provide the capacity needed to meet building demand. This measure may be used to simulate exclusively heat pump heated tanks, exclusively electrically heated tanks, or a combination of both.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # find all water heaters and get default volume
    default_vol = 80.0 # gallons
    if !model.getWaterHeaterMixeds.empty?
      model.getWaterHeaterMixeds.each do |wh|
        if wh.tankVolume.to_f > OpenStudio.convert(39, 'gal', 'm^3').to_f
          default_vol = [default_vol, OpenStudio.convert(wh.tankVolume.to_f,'m^3', 'gal').get.round(1)].max
        end
      end
    end
          
    # hot water tank volume 
    vol = OpenStudio::Measure::OSArgument.makeDoubleArgument('vol', true)
    vol.setDisplayName('Set hot water tank volume [gal]')
    vol.setDescription('Enter 0 to use existing tank volume(s). Values less than 5 are treated as sizing multipliers.')
    vol.setUnits('gal')
    vol.setDefaultValue(0)
    args << vol

    # heat pump capacity
    cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('cap', true)
    cap.setDisplayName('Set heat pump heating capacity. An input of zero will use the existing water heater capacity.')
    cap.setDescription('[kW]')
    cap.setDefaultValue(0)
    args << cap

    # heat pump COP
    cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('cop', true)
    cop.setDisplayName('Set heat pump rated COP (heating)')
    cop.setDefaultValue(3.2)
    args << cop

    # oversizing factor
    osz_factor = OpenStudio::Measure::OSArgument.makeDoubleArgument('osz_factor',true)
    osz_factor.setDisplayName("Oversizing Factor")
    osz_factor.setDescription("Sets a multiplier on autosized tank volume and heating capacity. Decimal values > 1.0 accepted.")
    osz_factor.setDefaultValue(1.0)
    args << osz_factor

    # electric resistance capacity 
    bu_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('bu_cap', true)
    bu_cap.setDisplayName('Set electric backup heating capacity. An input of zero will use existing heater capacity.')
    bu_cap.setDescription('[kW]')
    bu_cap.setDefaultValue((23.446 * (default_vol / 80.0)).round(1))
    args << bu_cap

    # heat pump evaporator location 
    # get ambient temp schedule or location from existing wh
    # else default to 70F schedule

    # define possible flex options
    flex_options = ['None', 'Charge - Heat Pump', 'Charge - Electric', 'Float']

    # create choice and string arguments for flex periods
    4.times do |n|
      flex = OpenStudio::Measure::OSArgument.makeChoiceArgument("flex#{n}", flex_options, true)
      flex.setDisplayName("Daily Flex Period #{n + 1}:")
      flex.setDescription('Applies every day in the full run period.')
      flex.setDefaultValue('None')
      args << flex

      flex_hrs = OpenStudio::Measure::OSArgument.makeStringArgument("flex_hrs#{n}", true)
      flex_hrs.setDisplayName('Use 24-Hour Format')
      flex_hrs.setDefaultValue('HH:MM - HH:MM')
      args << flex_hrs
    end


    # max temp
    max_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('max_temp', true)
    max_temp.setDisplayName('Set maximum tank temperature')
    max_temp.setDescription('[F]')
    max_temp.setDefaultValue(160)
    args << max_temp

    # min float temp
    min_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('min_temp', true)
    min_temp.setDisplayName('Set minimum tank temperature during float')
    min_temp.setDescription('[F]')
    min_temp.setDefaultValue(120)
    args << min_temp

    # create argument for deadband temperature difference between heat pump setpoint and electric backup
    db_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('db_temp', true)
    db_temp.setDisplayName('Set deadband temperature difference between heat pump and electric backup')
    db_temp.setDescription('[F]')
    db_temp.setDefaultValue(5)
    args << db_temp

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #### ARGUMENT VALIDATION ###############################################################################################
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign user inputs to variables in args hash
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args
      runner.registerError("Could not find measure input arguments")
      return false
    end

    # check arguments for reasonableness
    cap_check_vals = {'min' => 0, 'min_eq_bool' => true, 'arg_array' => ['cap', 'bu_cap']}
    cap_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, cap_check_vals)
    if !cap_vals_ok then return false end

    # assign arguments to variables
    vol = args['vol']
    cap = args['cap'] #heating capacity in kW
    cop = args['cop']
    bu_cap = args['bu_cap'] # backup heating capacity in kw
    osz_factor = args['osz_factor']
    
    flex = []
    flex_hrs = []
    flex_type = []
    4.times do |n|
      flex << args["flex#{n}"]
      flex_hrs << args["flex_hrs#{n}"]
    end

    max_temp = args['max_temp']
    max_temp_c = OpenStudio.convert(max_temp, 'F','C').get
    min_temp = args['min_temp']
    min_temp_c = OpenStudio.convert(min_temp, 'F', 'C').get
    db_temp = args['db_temp']
    db_temp_k = OpenStudio.convert(db_temp, 'R', 'K').get

    # parse flex_hrs into hours and minuts arrays
    hours = []
    minutes = []
    idx = 0
    flex_hrs.each do |fh|
      if flex[idx] != 'None'
        data = fh.split(/[-:]/)
        data.each { |e| e.delete!(' ') }
        if data[2] > data[0]
          flex_type << flex[idx]
          hours << data[0]
          hours << data[2]
          minutes << data[1]
          minutes << data[3]
        else
          flex_type << flex[idx]
          flex_type << flex[idx]
          hours << 0
          hours << data[2]
          hours << data[0]
          hours << 24
          minutes << 0
          minutes << data[3]
          minutes << data[1]
          minutes << 0
        end
      end
      idx += 1
    end

    # convert hours and minutes into OS:Time objects
    flex_times = []
    idx = 0
    hours.each do |h|
      flex_times << OpenStudio::Time.new(0, h.to_i, minutes[idx].to_i, 0)
      idx += 1
    end

    #### END ARGUMENT VALIDATION ###############################################################################################
    #### CONTROLS ###############################################################################################

    std = Standard.build('NREL ZNE Ready 2017')

    # get existing swh loops
    # should only just have one of these
    swh_loops = []
    model.getPlantLoops.each do |pl|
      if std.plant_loop_swh_loop?(pl)
        swh_loops << pl
      end
    end

    if swh_loops.empty?
      runner.registerFinalCondition("No Service Water Heating Loops found, no Heat Pump Water Heater will be added.")
      return true
    end

    swh_loops.each do |swh_loop|
      existing_heater = nil
      swh_loop.supplyComponents.each do |comp|
        if comp.iddObjectType.valueName.to_s == "OS_WaterHeater_Mixed"
          # exclude booster tanks (<10 gal)
          next if comp.to_WaterHeaterMixed.get.tankVolume.to_f < OpenStudio.convert(10, 'gal', 'm^3').get
          existing_heater = comp.to_WaterHeaterMixed.get
        end
      end
      if existing_heater.nil?
        runner.registerError("Did not find existing water heater")
        return false
      end
      
      puts "Volume: #{vol}"
      if vol == 0
        if existing_heater.tankVolume.is_initialized
          v = existing_heater.tankVolume.to_f
        else
          # todo: run sizing run
          runner.registerWarning("Existing heater volume not set. Assuming default 80 gal.")
          v = OpenStudio.convert(80, 'gal', 'm^3').get
        end
      else
        v = OpenStudio.convert(vol, 'gal', 'm^3').get
      end

      if cap == 0
        if existing_heater.heaterMaximumCapacity.is_initialized
          cap = existing_heater.heaterMaximumCapacity.get * osz_factor / 1000
        else
          # todo: run sizing run
          runner.registerWarning("Existing heater heating capacity not set. Using default value based on volume.")
          cap = 23.446 * (default_vol / 80.0) * osz_factor
        end
      end
      if bu_cap == 0
        bu_cap = cap
      end
      
      inlet = existing_heater.supplyInletModelObject.get.to_Node.get
      outlet = existing_heater.supplyOutletModelObject.get.to_Node.get

      # heater and tank controls
      # get existing temperature schedule
      if existing_heater.setpointTemperatureSchedule.is_initialized
        swh_temp_sch = existing_heater.setpointTemperatureSchedule.get.to_ScheduleRuleset.get
        swh_temp_c = OsLib_Schedules.getMinMaxAnnualProfileValue(model, swh_temp_sch)['max']
        swh_temp_f = OpenStudio.convert(swh_temp_c, 'C','F').get
      else
        # create new with default 140F
        swh_temp_f = 140
        swh_temp_c = OpenStudio.convert(swh_temp_f, 'F','C').get
        swh_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model, swh_temp_c)
              # temperature schedule type limits
        temp_sch_type_limits = stsd.model_add_schedule_type_limits(model,
                                                              name: 'Temperature Schedule Type Limits',
                                                              lower_limit_value: 0.0,
                                                              upper_limit_value: 100.0,
                                                              numeric_type: 'Continuous',
                                                              unit_type: 'Temperature')
        swh_temp_sch.setScheduleTypeLimits(temp_sch_type_limits)
      end

      # create new tank temp setpoint
      tank_sch = OpenStudio::Model::ScheduleRuleset.new(model, swh_temp_c - db_temp_k + 2)
      tank_sch.setName("Tank Electirc Heater Setpoint")
      tank_sch.defaultDaySchedule.setName("#{tank_sch.name.get} Default")

      swh_d_day = swh_temp_sch.defaultDaySchedule
      tank_d_day = tank_sch.defaultDaySchedule
      old_times = swh_d_day.times
      old_values = swh_d_day.values
      new_swh_values = Array.new(flex_times.size, 2)
      new_tank_values = Array.new(flex_times.size, 2)


      flex_times.size.times do |i|
        if i.even?
          n = 0
          old_times.each do |ot|
            new_swh_values[i] = old_values[n] if flex_times[i] <= ot
            new_tank_values[i] = old_values[n] if flex_times[i] <= ot
            n += 1
          end
        elsif flex_type[(i/2).floor] == 'Charge - Heat Pump'
          new_swh_values[i] = max_temp_c
          new_tank_values[i] = max_temp_c - db_temp_k
        elsif flex_type[(i/2).floor] == 'Float'
          new_swh_values[i] = min_temp_c
          new_tank_values[i] = min_temp_c - db_temp_k
        elsif flex_type[(i/2).floor] == 'Charge - Electric'
          new_swh_values[i] = min_temp_c
          new_tank_values[i] = max_temp_c
        end
      end

      # create new rules and add to default day based on flex period options above
      idx = 0
      flex_times.each do |ft|
        swh_d_day.addValue(ft, new_swh_values[idx])
        tank_d_day.addValue(ft, new_tank_values[idx])
        idx += 1
      end
      
      #### END CONTROLS ###############################################################################################


      # default hpwh type to 'wrapped condenser' for now 
      type = 'WrappedCondenser'

      # add heat pump water heater and attach to selected loop
      hpwh = std.model_add_heatpump_water_heater(model,
                                                 type: type,
                                                 water_heater_capacity: (cap * 1000),
                                                 electric_backup_capacity: (bu_cap * 1000),
                                                 water_heater_volume: v,
                                                 service_water_temperature: swh_temp_c,
                                                 parasitic_fuel_consumption_rate: 3.0,
                                                 swh_temp_sch: nil,
                                                 cop: cop,
                                                 shr: 0.88,
                                                 tank_ua: 3.9,
                                                 set_peak_use_flowrate: false,
                                                 peak_flowrate: 0.0,
                                                 flowrate_schedule: nil,
                                                 water_heater_thermal_zone: nil
                                                 )

      # max temp
      hpwh.setDeadBandTemperatureDifference(db_temp_k)
      tank = hpwh.tank.to_WaterHeaterStratified.get
      tank.addToNode(inlet)
      inlet.setName("#{tank.name.get} Supply Inlet Water Node")
      tank.supplyOutletModelObject.get.to_Node.get.setName("#{tank.name.get} Supply Outlet Water Node")
      runner.registerInfo("#{hpwh.name} was added to the model on #{swh_loop.name}")

      # remove existing
      runner.registerInfo("#{existing_heater.name} was removed from the model.")
      existing_heater.remove

      clg_coil_name = hpwh.dXCoil.name.get
      tank_name = tank.name.get

      hpwh.setCompressorSetpointTemperatureSchedule(swh_temp_sch)

      tank.setHeater1SetpointTemperatureSchedule(tank_sch)
      tank.setHeater2SetpointTemperatureSchedule(tank_sch)

      
    ## ADD REPORTED VARIABLES ------------------------------------------------------------------------------------------
      add_output = true

      if add_output
          
        ovar_names = ['Cooling Coil Total Cooling Rate',
        'Cooling Coil Total Water Heating Rate',
        'Cooling Coil Water Heating Electric Power',
        'Cooling Coil Crankcase Heater Electric Power',
        'Water Heater Tank Temperature',
        'Water Heater Heat Loss Rate',
        'Water Heater Heating Rate',
        'Water Heater Use Side Heat Transfer Rate',
        'Water Heater Source Side Heat Transfer Rate',
        'Water Heater Unmet Demand Heat Transfer Rate',
        'Water Heater Electricity Rate',
        'Water Heater Water Volume Flow Rate',
        'Water Use Connections Hot Water Temperature']

        # Create new output variable objects
        ovars = []
        ovar_names.each do |nm|
          ov = OpenStudio::Model::OutputVariable.new(nm, model)
          if nm.include?("Cooling Coil")
            ov.setKeyValue(clg_coil_name)
          else
            ov.setKeyValue(tank_name)
          end
          ovars << ov
        end

        [swh_temp_sch,  tank_sch].each do |sch|
          # add temperate schedule outputs
          v = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
          v.setKeyValue(sch.name.to_s)
          ovars << v
        end

        # Set variable reporting frequency for newly created output variables
        ovars.each do |var|
          var.setReportingFrequency('TimeStep')
        end

        # Register info re: output variables:
        runner.registerInfo("#{ovars.size} output variables were added to the model.")

      end
        ## END ADD REPORTED VARIABLES --------------------------------------------------------------------------------------

    end

    # Register final condition
    # hpwh_fc = model.getWaterHeaterHeatPumps.size + model.getWaterHeaterHeatPumpWrappedCondensers.size
    # tanks_fc = model.getWaterHeaterMixeds.size + model.getWaterHeaterStratifieds.size

    runner.registerFinalCondition("The building finished with #{swh_loops.size} water heater tank(s) " \
                                  "and #{swh_loops.size} heat pump water heater(s).")


    return true
  end
end

# register the measure to be used by the application
SCEReplaceExistingDHWWithHeatPumpWaterHeater.new.registerWithApplication
