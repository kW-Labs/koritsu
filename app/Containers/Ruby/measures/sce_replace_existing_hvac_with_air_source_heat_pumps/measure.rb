# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/



# start the measure
class SCEReplaceExistingHVACWithAirSourceHeatPumps < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods'
  require 'openstudio/extension/core/os_lib_model_generation.rb'
  # resource file modules
  include OsLib_HelperMethods
  include OsLib_ModelGeneration
  # include Standard

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Replace Existing HVAC with Air Source Heat Pumps'
  end

  # human readable description
  def description
    return 'Replaces existing building HVAC systems with one of a selection of air-source heat pump systems. Heat pump rated heating COP will be a user input. Cooling and primary equipment efficiency will be set according to DEER standards for the selected DEER vintage. '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will remove all exisiting HVAC equipment and replace them with the user-selected system type. Packaged single-zone systems will be applied to each zone; DOAS systems will create DOAS per floor, with FCUs per zone. One AHU will be created per floor with one reheat terminal per zone. Hydronic systems will receive one heating and one cooling plant loop per building. 
System capacity will be auto-sized by the simulation program. Cooling efficiency will be set per DEER vintage, heat pump efficiency will be user-enterable, with one value applied to all heat pump heating equipment added.  
'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # see if building name contains any template values
    default_string = "DEER 2020"
    get_deer_templates.each do |template_string|
      if model.getBuilding.name.to_s.include?(template_string)
        default_string = template_string
        next
      end
    end

    # Make argument for template
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('template', get_deer_templates, true)
    template.setDisplayName('Target DEER Standard')
    template.setDefaultValue(default_string)
    args << template

    # Make argument for system type
    hvac_system_chs = OpenStudio::StringVector.new
    hvac_system_chs << "Packaged Single-Zone Heat Pumps (i.e. split systems)"
    hvac_system_chs << "Packaged Single-Zone AC with Hydronic Heating via Central Air-Water Heat Pump"
    hvac_system_chs << "DOAS with Fan Coil Units, CHW via Air-Cooled Chiller, Heating via Central Air-Water Heat Pump"
    hvac_system_chs << "VAV AHU, CHW via Air-Cooled Chiller, Heating and Reheat via Central Air-Water Heat Pump"

    system_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('system_type', hvac_system_chs, true)
    system_type.setDisplayName('HVAC System Type')
    system_type.setDefaultValue('Packaged Single-Zone Heat Pumps (i.e. split systems)')
    args << system_type

    cool_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('cool_cop', true)
    cool_cop.setDisplayName("Heat Pump Cooling Rated COP")
    cool_cop.setDescription("This value will be applied to all zone-level or plant-level cooling equipment")
    cool_cop.setDefaultValue(3.0)
    args << cool_cop

    heat_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('heat_cop', true)
    heat_cop.setDisplayName("Heat Pump Heating Rated COP")
    heat_cop.setDescription("This value will be applied to all zone-level or plant-level heating equipment")
    heat_cop.setDefaultValue(3.0)
    args << heat_cop


    return args
  end

  # open channel to log info/warning/error messages
  def setup_log_msgs(runner, debug = false)
    # Open a channel to log info/warning/error messages
    @msg_log = OpenStudio::StringStreamLogSink.new
    if debug
      @msg_log.setLogLevel(OpenStudio::Debug)
    else
      @msg_log.setLogLevel(OpenStudio::Info)
    end
    @start_time = Time.new
    @runner = runner
  end

  # Get all the log messages and put into output
  # for users to see.
  def log_msgs_to_file(debug, filename)
    # Log the messages to file for easier review
    log_name = "#{filename}.log"
    log_file_path = "#{Dir.pwd}/#{log_name}"
    messages = log_messages_to_file(log_file_path, debug)
    @runner.registerFinalCondition("Messages below saved to <a href='file:///#{log_file_path}'>#{log_name}</a>.")
    @msg_log.logMessages.each do |msg|
      # DLM: you can filter on log channel here for now
      if /openstudio.*/.match(msg.logChannel) # /openstudio\.model\..*/
        # Skip certain messages that are irrelevant/misleading
        next if msg.logMessage.include?('Skipping layer') || # Annoying/bogus "Skipping layer" warnings
                msg.logChannel.include?('runmanager') || # RunManager messages
                msg.logChannel.include?('setFileExtension') || # .ddy extension unexpected
                msg.logChannel.include?('Translator') || # Forward translator and geometry translator
                msg.logMessage.include?('UseWeatherFile') || # 'UseWeatherFile' is not yet a supported option for YearDescription
                msg.logMessage.include?('has multiple parents') # 'has multiple parents' is thrown for various types of curves if used in multiple objects

        # Report the message in the correct way
        if msg.logLevel == OpenStudio::Info
          @runner.registerInfo(msg.logMessage)
        elsif msg.logLevel == OpenStudio::Warn
          @runner.registerWarning("[#{msg.logChannel}] #{msg.logMessage}")
        elsif msg.logLevel == OpenStudio::Error
          @runner.registerError("[#{msg.logChannel}] #{msg.logMessage}")
        elsif msg.logLevel == OpenStudio::Debug && @debug
          @runner.registerInfo("DEBUG - #{msg.logMessage}")
        end
      end
    end
    @runner.registerInfo("Total Time = #{(Time.new - @start_time).round}sec.")
  end

  def apply_standard_efficiency(model, climate_zone, standard)

    build_dir = "#{Dir.pwd}/output"
    if !Dir.exist?(build_dir)
      Dir.mkdir(build_dir)
    end

    # Set the heating and cooling sizing parameters
    standard.model_apply_prm_sizing_parameters(model)

    # perform a sizing run 
    sizing_run_success = standard.model_run_sizing_run(model, "#{build_dir}/SR")
    unless sizing_run_success
      return false
    end

    # If there are any multizone systems, reset damper positions to achieve a 60% ventilation effectiveness minimum for the system
    # following the ventilation rate procedure from 62.1
    standard.model_apply_multizone_vav_outdoor_air_sizing(model)

    # Set the baseline fan power for all airloops
    model.getAirLoopHVACs.sort.each do |air_loop|
      standard.air_loop_hvac_apply_prm_baseline_fan_power(air_loop)
    end

    # Set the baseline fan power for all zone HVAC
    model.getZoneHVACComponents.sort.each do |zone_hvac|
      standard.zone_hvac_component_apply_prm_baseline_fan_power(zone_hvac)
    end

    # Set the pumping control strategy and power
    # Must be done after sizing components
    model.getPlantLoops.sort.each do |plant_loop|
      # Skip the SWH loops
      next if standard.plant_loop_swh_loop?(plant_loop)

      standard.plant_loop_apply_prm_baseline_pump_power(plant_loop)
      standard.plant_loop_apply_prm_baseline_pumping_type(plant_loop)
    end

    # apply_efficiency_success = standard.model_apply_hvac_efficiency_standard(model, climate_zone)
    # unless apply_efficiency_success
    #   @runner.registerError("Failed to apply standard efficiencies after sizing run for model")
    #   return false
    # end
    return model
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # debug = false
    # # Open a channel to log info/warning/error messages
    # setup_log_msgs(runner, debug)
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args
      runner.registerError("Could not find measure input arguments")
      return false
    end

    # check the cool/heat cop for reasonableness
    arg_check_hash = {
      'min' => 0,
      'min_eq_bool' => true,
      'max' => 6,
      'max_eq_bool' => true,
      'arg_array' => ['cool_cop', 'heat_cop']
    }
    cop_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, arg_check_hash)
    if !cop_vals_ok then return false end

    # assign args to variables
    cool_cop = args['cool_cop']
    heat_cop = args['heat_cop']
    system_type = args['system_type']
    template = args['template']

    # create standards object
    std = Standard.build(template)

    zones = model.getThermalZones
    plenum_zones = zones.select { |zone| std.thermal_zone_plenum?(zone) }
    heated_and_cooled_zones = zones.select { |zone| std.thermal_zone_heated?(zone) && std.thermal_zone_cooled?(zone) }
    heated_zones = zones.select { |zone| std.thermal_zone_heated?(zone) }
    cooled_zones = zones.select { |zone| std.thermal_zone_cooled?(zone) }
    cooled_only_zones = zones.select { |zone| !std.thermal_zone_heated?(zone) && std.thermal_zone_cooled?(zone) }
    heated_only_zones = zones.select { |zone| std.thermal_zone_heated?(zone) && !std.thermal_zone_cooled?(zone) }
    system_zones = heated_and_cooled_zones + cooled_only_zones


    # report initial condition of model
    # number of conditioned, non-plenum zones
    message_str = "The building started with #{system_zones.size} conditioned zones which will have their HVAC replaced by the selected system type."
    if plenum_zones.size > 0
      message_str << " #{plenum_zones} have been detected as Plenums, which will be skipped."
    end
    runner.registerInitialCondition(message_str)

    # remove existing hvac equipment
    std.remove_hvac(model)
    
    # get climate zone string from model
    climate_zone = nil
    cz = model.getClimateZones
    if cz.getClimateZones("CEC").empty?
      runner.registerError("Model does not have CEC Climate Zone assigned. Cannot apply HVAC efficiency standard for #{template}.")
    else
      cz_num = cz.getClimateZones("CEC").first.value
      climate_zone = "CEC T224-CEC#{cz_num.to_s}"
    end

    # map hvac system choice args to add_cbecs_hvac_system
    case system_type
    when "Packaged Single-Zone Heat Pumps (i.e. split systems)"
      std.model_add_hvac_system(model, 'PSZ-HP', ht = 'Electricity', znht = nil, cl = 'Electricity', system_zones)
      apply_standard_efficiency(model, climate_zone, std)
      # set COPs
      model.getCoilCoolingDXSingleSpeeds.each {|c| c.setRatedCOP(cool_cop)}
      model.getCoilHeatingDXSingleSpeeds.each {|c| c.setRatedCOP(heat_cop)}
    when "Packaged Single-Zone AC with Hydronic Heating via Central Air-Water Heat Pump"
      std.model_add_hvac_system(model, 'PSZ-AC', ht = 'AirSourceHeatPump', znht = nil, cl = 'Electricity', system_zones)
      apply_standard_efficiency(model, climate_zone, std)
      # set COPs
      model.getCoilCoolingDXSingleSpeeds.each {|c| c.setRatedCOP(cool_cop)}
      # ASHP heat pump COP is set as the constant term coefficient of a curve referenced by the EMS:CurveOrTableIndexVariable
      model.getEnergyManagementSystemCurveOrTableIndexVariables.each do |var|
        curve = var.curveOrTableObject
        if curve.to_CurveQuadratic.is_initialized
          curve = curve.to_CurveQuadratic.get
          constant_coeff_new = 1.932 + (heat_cop - 3.65)
          curve.setCoefficient1Constant(constant_coeff_new)
        else
          runner.registerError("Could not find Central ASHP")
          return false
        end
      end

    when "DOAS with Fan Coil Units, CHW via Air-Cooled Chiller, Heating via Central Air-Water Heat Pump"
      std.model_add_hvac_system(model, 'DOAS', ht = 'AirSourceHeatPump', znht = nil, cl = 'Electricity', system_zones, chilled_water_loop_cooling_type: 'AirCooled')
      std.model_add_hvac_system(model, 'Fan Coil', ht = 'AirSourceHeatPump', znht = nil, cl = 'Electricity', system_zones, chilled_water_loop_cooling_type: 'AirCooled', zone_equipment_ventilation: false)
      apply_standard_efficiency(model, climate_zone, std)
      # set COPs
      model.getChillerElectricEIRs.each {|ch| ch.setReferenceCOP(cool_cop)}
      # ASHP heat pump COP is set as the constant term coefficient of a curve referenced by the EMS:CurveOrTableIndexVariable
      model.getEnergyManagementSystemCurveOrTableIndexVariables.each do |var|
        curve = var.curveOrTableObject
        if curve.to_CurveQuadratic.is_initialized
          curve = curve.to_CurveQuadratic.get
          constant_coeff_new = 1.932 + (heat_cop - 3.65)
          curve.setCoefficient1Constant(constant_coeff_new)
        else
          runner.registerError("Could not find Central ASHP")
          return false
        end
      end
    when "VAV AHU, CHW via Air-Cooled Chiller, Heating and Reheat via Central Air-Water Heat Pump"
      std.model_add_hvac_system(model, 'VAV Reheat', ht = 'AirSourceHeatPump', znht = 'AirSourceHeatPump', cl = 'Electricity', system_zones, chilled_water_loop_cooling_type: 'AirCooled')
      apply_standard_efficiency(model, climate_zone, std)
      # set COPs
      model.getChillerElectricEIRs.each {|ch| ch.setReferenceCOP(cool_cop)}
      # ASHP heat pump COP is set as the constant term coefficient of a curve referenced by the EMS:CurveOrTableIndexVariable
      model.getEnergyManagementSystemCurveOrTableIndexVariables.each do |var|
        curve = var.curveOrTableObject
        if curve.to_CurveQuadratic.is_initialized
          curve = curve.to_CurveQuadratic.get
          constant_coeff_new = 1.932 + (heat_cop - 3.65)
          curve.setCoefficient1Constant(constant_coeff_new)
        else
          runner.registerError("Could not find Central ASHP")
          return false
        end
      end
    end

    # log_msgs_to_file(debug, "add_ashp_output")

    return true
  end
end

# register the measure to be used by the application
SCEReplaceExistingHVACWithAirSourceHeatPumps.new.registerWithApplication
