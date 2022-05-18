# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddChilledWaterStorage < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation'
  require 'openstudio/extension/core/os_lib_schedules'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add Chilled Water Storage'
  end

  # human readable description
  def description
    return 'This measure adds a chilled water thermal energy storage tank to the model for the purpose load shifting.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure allows users attach chilled water thermal energy storage (CWTS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. '\
           'The baseline chilled water loop will be split into a \'primary\' and \'secondary\' loop, with the primary loop contiaing the existing chiller (hardsized to maintain baseline sizing) on the supply side '\
           'and a ThermalStorage:ChilledWater:Stratified on the demand side. The secondary loop contains the chilled water tank on the supply side and existing chilled water coils on the demand side. '\
           'The chilled water tank is modeled as a vertical cylinder with minimal surface area for a given tank volume. Tank is assumed to be exposed to ambient conditions, with a surface U-value of 0.5 W/m^2*K'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # storage tank volume
    tank_vol = OpenStudio::Measure::OSArgument.makeDoubleArgument('tank_vol', true)
    tank_vol.setDisplayName("Chilled Water Storage Tank Volume (ft^3)")
    tank_vol.setDescription("Storage volume of chilled water tank in cubic feet.")
    tank_vol.setDefaultValue(2000) # 56 m^3, about 15,000 gal
    args << tank_vol

    # storage tank cooling capacity (kW)
    stor_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('stor_cap', true)
    stor_cap.setDisplayName("Chilled Water Storage Cooling Capacity (tons)")
    stor_cap.setDescription("Cooling capacity of chilled water thermal storage tank in tons")
    stor_cap.setDefaultValue(300)
    args << stor_cap

    # daily charge hours - same as battery storage
    charge_hours = OpenStudio::Measure::OSArgument.makeStringArgument('charge_hours', true)
    charge_hours.setDisplayName("Storage Charge Hours")
    charge_hours.setDescription("Enter daily times for battery charging, using 24-hour format. Applies every day in the full run period.")
    charge_hours.setDefaultValue('HH:MM - HH:MM')
    args << charge_hours

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
  
  # calculates the height of a cylinder of a given volume to minimize surface area
  def calc_cylinder_height(vol)
    h = ((4.0 * vol) / Math::PI) ** (1.0/3)
    return h
  end

  class OpenStudio::Model::ModelObject
    # from Julien Marrec
    # https://unmethours.com/question/17616/get-thermal-zone-supply-terminal/
    # Extend ModelObject class to add a to_actual_object method
    # Casts a ModelObject into what it actually is (OS:Node for example...)
    def to_actual_object
      obj_type = self.iddObjectType.valueName
      obj_type_name = obj_type.gsub('OS_','').gsub('_','')
      method_name = "to_#{obj_type_name}"
      if self.respond_to?(method_name)
        actual_thing = self.method(method_name).call
        if !actual_thing.empty?
            return actual_thing.get
        end
      end
      return false
    end
    
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
    tank_vol = args['tank_vol']
    stor_cap = args['stor_cap']
    charge_hours = args['charge_hours']

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

    # run sizing run
    std = Standard.build("90.1-2013")
    if std.model_run_sizing_run(model, "#{Dir.pwd}/SR") == false
      runner.registerError("Sizing Run of baseline model failed.")
      return false
    end


    cooling_plantloops.each do |plant|
      loop_name = plant.name.get
      siz = plant.sizingPlant

      # hardsize loop and supply components
      plant.applySizingValues
      plant.supplyComponents.each do |comp|
        comp = comp.to_actual_object
        if comp.respond_to?("applySizingValues")
          comp.applySizingValues
        end
      end

      plant.demandComponents.each do |comp|
        if comp.iddObjectType.valueName.include?("Pump")
          comp = comp.to_actual_object
          comp.applySizingValues
        end
      end

      runner.registerInfo("Converting #{loop_name} to a Primary/Secondary loop configuration.")
      # clone existing plant loop to use as primary 
      new_loop = plant.clone(model).to_PlantLoop.get
      new_loop.setName("Primary #{loop_name}")

      # remove chiller from old loop 
      plant.supplyComponents.each do |comp|
        if comp.iddObjectType.valueName.include?("Chiller")
          comp.remove 
        end
      end
      
      
      
      # check for common pipe simulation
      if plant.commonPipeSimulation.get.include?("CommonPipe")
        new_loop.setCommonPipeSimulation("None")
        plant.setCommonPipeSimulation("None")
        # delete primary pump
        plant.supplyComponents.each do |comp|
          if comp.iddObjectType.valueName.include?("Pump")
            comp.remove
          end
        end
      end

      # move secondary pump
      sec_pump = nil
      plant.demandComponents.each do |comp|
        if comp.iddObjectType.valueName.include?("Pump")
          sec_pump = comp.to_actual_object
        end
      end
      unless sec_pump.nil?
        sec_pump.addToNode(plant.supplyInletNode)
        runner.registerInfo("Moved secondary pump to be primary loop on #{loop_name}")
      end

      # delete secondary pump on new loop
      new_loop.demandComponents.each do |comp|
        if comp.iddObjectType.valueName.include?("Pump")
          comp.remove
          runner.registerInfo("Removed secondary pump on #{new_loop.name.get}")
        end
      end


      flow = plant.autosizedMaximumLoopFlowRate
      if flow.is_initialized
        flow = flow.get
        runner.registerInfo("Existing plant #{loop_name} Autosized flow rate: #{flow} m3/s")
      else
        runner.registerWarning("existing loop flow not found!")
      end

      vol_si = OpenStudio.convert(tank_vol, "ft^3", "m^3").get
      tank_h = calc_cylinder_height(vol_si)
      
      # create thermal storage tank and add to primary and secondary loops
      ts = OpenStudio::Model::ThermalStorageChilledWaterStratified.new(model)
      ts.setName("#{loop_name} Chilled Water Storage Tank")
      ts.setTankVolume(OpenStudio.convert(tank_vol, 'ft^3', 'm^3').get)
      ts.setTankHeight(tank_h)
      ts.setTemperatureSensorHeight(0.8 * tank_h)
      ts.setMinimumTemperatureLimit(1.0)
      ts.setNominalCoolingCapacity(OpenStudio.convert(stor_cap, 'ton', 'W').get)
      # # schedule for ambient temperature
      # amb_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model, OpenStudio.convert(72, "F","C").get)
      # amb_temp_sch.setName("Chilled Water Storage Tank Ambient Temp Constant 72F")
      # amb_temp_sch.setScheduleTypeLimits(get_temperature(model))
      # ts.setAmbientTemperatureIndicator("Schedule")
      # ts.setAmbientTemperatureSchedule(amb_temp_sch)
      ts.setAmbientTemperatureIndicator("Exterior")
      ts.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(0.5)
      ts.setUseSideHeatTransferEffectiveness(1.0)
      ts.setUseSideInletHeight(0.9 * tank_h)
      ts.setUseSideOutletHeight(0.18 * tank_h)
      ts.setSourceSideHeatTransferEffectiveness(1.0)
      ts.setSourceSideInletHeight(0.18 * tank_h)
      ts.setSourceSideOutletHeight(0.9 * tank_h)
      # ts.setSourceSideDesignFlowRate()
      ts.setTankRecoveryTime(4)
      ts.setInletMode("Fixed")
      ts.setNumberofNodes(6)
      
      # connect to plant loops
      plant.addSupplyBranchForComponent(ts)
      new_loop.addDemandBranchForComponent(ts)

      # set up controls
      # setpoint temp schedule - same as SPM Sch
      spm = new_loop.loopTemperatureSetpointNode.setpointManagers.first
      if spm.to_SetpointManagerScheduled.is_initialized
        temp_sch = spm.to_SetpointManagerScheduled.get.schedule
      elsif spm.to_SetpointManagerOutdoorAirReset.is_initialized
        set_temp = spm.to_SetpointManagerOutdoorAirReset.get.setpointAtOutdoorHighTemperature
        temp_sch = OpenStudio::Model::ScheduleRuleset.new(model, set_temp)
        temp_sch.setName("CHW Tank Temp Sch")
      end
      ts.setSetpointTemperatureSchedule(temp_sch)

      # charge time schedule - 1 for charge hours
      charge_sch = create_charge_fraction_schedule(model, os_times_from_string(charge_hours))
      ts.setSourceSideAvailabilitySchedule(charge_sch)
      
      runner.registerInfo("Added Thermal Storage to #{loop_name}")
    end

    add_ov = true
    if add_ov
      ov_names = [
        "Chilled Water Thermal Storage Tank Temperature",
        "Chilled Water Thermal Storage Final Tank Temperature",
        "Chilled Water Thermal Storage Tank Heat Gain Rate",
        "Chilled Water Thermal Storage Tank Heat Gain Energy",
        "Chilled Water Thermal Storage Use Side Mass Flow Rate",
        "Chilled Water Thermal Storage Use Side Inlet Temperature",
        "Chilled Water Thermal Storage Use Side Outlet Temperature",
        "Chilled Water Thermal Storage Use Side Heat Transfer Rate",
        "Chilled Water Thermal Storage Use Side Heat Transfer Energy",
        "Chilled Water Thermal Storage Source Side Mass Flow Rate",
        "Chilled Water Thermal Storage Source Side Inlet Temperature",
        "Chilled Water Thermal Storage Source Side Outlet Temperature",
        "Chilled Water Thermal Storage Source Side Heat Transfer Rate",
        "Chilled Water Thermal Storage Source Side Heat Transfer Energy"
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
SCEAddChilledWaterStorage.new.registerWithApplication
