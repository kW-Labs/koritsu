# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_model_generation.rb'
require_relative 'resources/SCE_Hvac.rb'

# start the measure
class SCEReplaceExistingHVACWithGroundSourceHeatPumps < OpenStudio::Measure::ModelMeasure
  # resource file modules
  include OsLib_HelperMethods
  include OsLib_ModelGeneration

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Replace Existing HVAC with Ground Source Heat Pumps'
  end

  # human readable description
  def description
    return 'Replaces building HVAC systems with one of a selection of Ground-source heat pump configurations, with user-input cooling and heating rated efficiencies. A ground loop will be created to reject/obtain heat for water-source heat pumps that approximates a properly sized ground heat exchanger without requiring a detailed ground loop sizing simulation.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will remove all the existing building HVAC systems and replace them with the user-specified system. A ground-source heat pump will be added to each zone in the model. The option to add a dedicated outdoor air system (DOAS) will add one per floor to provide pre-conditioned ventilation air to the zones. DOAS cooling source can be either packaged DX or GSHP; DOAS heating source can be gas furnace, electric resistance, packaged DX (heat pump) or WSHP. User will be able to input efficiencies for DOAS cooilng and heating source, to be applied to all DOASs.
The GSHPs will reject heat to a common ground loop. The ground loop capacity will be approximated by a linear function of temperature difference across the loop – this measure does not specificlly size a ground loop. 
User input of GSHP cooling and heating efficiency will be applied equally to all zone-level heat pumps added. 
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

    # DOAS bool
    doas = OpenStudio::Measure::OSArgument.makeBoolArgument('doas', true)
    doas.setDisplayName("Add Dedicated Outdoor Air System (DOAS)")
    doas.setDescription("If selected, a Dedicated Outdoor Air System will be added per floor to precondition outside air delivered to the zones.")
    doas.setDefaultValue(false)
    args << doas

    # DOAS Cooling Source
    doas_cool = OpenStudio::Measure::OSArgument.makeChoiceArgument('doas_cool', ['WSHP', 'DX', 'No DOAS'], true)
    doas_cool.setDisplayName("Cooling Source for DOAS")
    doas_cool.setDescription("Sets the cooling source for the Dedicated Outside Air System.")
    doas_cool.setDefaultValue("No DOAS")
    args << doas_cool

    # DOAS Cooling Efficiency
    doas_cool_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('doas_cool_cop', true)
    doas_cool_cop.setDisplayName("DOAS Cooling Source Rated COP")
    doas_cool_cop.setDescription("This value will be applied to DOAS cooling equipment")
    doas_cool_cop.setDefaultValue(3.0)
    args << doas_cool_cop

    # DOAS Heating Source
    doas_heat = OpenStudio::Measure::OSArgument.makeChoiceArgument('doas_heat', ['Gas Furnace', 'Electric Resistance', 'WSHP', 'Air Source Heat Pump', 'No DOAS'], true)
    doas_heat.setDisplayName("Heating Source for DOAS")
    doas_heat.setDescription("Sets the heating source for the Dedicated Outside Air System.")
    doas_heat.setDefaultValue("No DOAS")
    args << doas_heat

    # DOAS Heating Efficiency 
    doas_heat_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('doas_heat_cop', true)
    doas_heat_cop.setDisplayName("DOAS Heating Source Rated Efficiency")
    doas_heat_cop.setDescription("This value will be applied to DOAS heating equipment.\nFor gas furnace, enter a value less than 1 as furnace AFUE.\nFor Electric resistance, enter 1.0.\nFor WSHP/Air-source heat pump this is rated COP (>1).")
    doas_heat_cop.setDefaultValue(1)
    args << doas_heat_cop

    
    # gSHP Cooling COP
    cool_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('cool_cop', true)
    cool_cop.setDisplayName("Ground-Source Heat Pump Cooling Rated COP")
    cool_cop.setDescription("This value will be applied to all zone-level GSHP equipment in cooling.")
    cool_cop.setDefaultValue(3.0)
    args << cool_cop

    # WSHP Heating COP
    heat_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('heat_cop', true)
    heat_cop.setDisplayName("Ground-Source Heat Pump Heating Rated COP")
    heat_cop.setDescription("This value will be applied to all zone-level GSHP equipment in heating.")
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
                msg.logMessage.include?('has multiple parents') ||# 'has multiple parents' is thrown for various types of curves if used in multiple objects
                msg.logMessage.include?('method is deprecated')
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

  # run sizing run and set standard efficiency values
  def apply_standard_efficiency(model, climate_zone, standard)
    build_dir = "#{Dir.pwd}/output"
    if !Dir.exist?(build_dir)
      Dir.mkdir(build_dir)
    end

    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)
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
      'arg_array' => ['doas_cool_cop', 'cool_cop', 'heat_cop']
    }
    cop_vals_ok = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, arg_check_hash)
    if !cop_vals_ok then return false end
  
    # assign args to variables
    doas_bool = args['doas']
    doas_cool = args['doas_cool']
    doas_cool_cop = args['doas_cool_cop']
    doas_heat = args['doas_heat']
    doas_heat_cop = args['doas_heat_cop']
    cool_cop = args['cool_cop']
    heat_cop = args['heat_cop']
    template = args['template']

    # check doas args for consistency
    if !doas_bool
      if !doas_cool == "No DOAS"
        runner.registerWarning("DOAS cooling source entered, but Add Dedicated Outdoor Air System argument not selected. No DOAS will be created.")
      end
      if !doas_heat == "NO DOAS"
        runner.registerWarning("DOAS heating source entered, but Add Dedicated Outdoor Air System argument not selected. No DOAS will be created.")
      end
    end

    # create standards object
    std = Standard.build(template)

    # get zones
    zones = model.getThermalZones
    # heated and cooled zones
    plenum_zones = zones.select { |zone| std.thermal_zone_plenum?(zone) }
    heated_and_cooled_zones = zones.select { |zone| std.thermal_zone_heated?(zone) && std.thermal_zone_cooled?(zone) }
    cooled_only_zones = zones.select { |zone| !std.thermal_zone_heated?(zone) && std.thermal_zone_cooled?(zone) }
    heated_only_zones = zones.select { |zone| std.thermal_zone_heated?(zone) && !std.thermal_zone_cooled?(zone) }
    system_zones = heated_and_cooled_zones + cooled_only_zones - plenum_zones
    # zones grouped by story
    zones_by_story = std.model_group_zones_by_story(model, system_zones)

    # report initial condition of model
    # number of conditioned, non-plenum zones
    message_str = "The building started with #{system_zones.size} conditioned zones which will have their HVAC replaced by the selected system type."
    if plenum_zones.size > 0
      message_str << " #{plenum_zones.size} have been detected as Plenums, which will be skipped."
    end
    runner.registerInitialCondition(message_str)

    # remove existing hvac
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

    # add ground loop
    hx_loop = std.model_add_ground_hx_loop(model)

    # ventilation flag
    zone_vent = true

    # final condition message
    final_cond_message = ""

    # create doas
    if doas_bool
      doas_heat_source_map = {'Gas Furnace'=>'NaturalGas', 'Electric Resistance'=>'Electricity', 'WSHP'=>'WSHP', 'Air Source Heat Pump'=>'DX'}
      zones_by_story.each_with_index do |zone_group, i|
        story = zone_group.first.spaces.first.buildingStory
        if story.is_initialized
          story_name = story.get.name.get 
        else
          story_name = "Building Story #{i}"
        end
        # create doas with efficiencies
        std.model_add_doas_custom(model, 
                                  zone_group, 
                                  system_name: "#{story_name} DOAS", 
                                  cooling_source: doas_cool, 
                                  cooling_eff: doas_cool_cop, 
                                  heating_source: doas_heat_source_map[doas_heat],
                                  heating_eff: doas_heat_cop,
                                  condenser_loop: hx_loop)
      end
      final_cond_message << "#{zones_by_story.size} Dedicated Outside Air Units created providing ventilation to #{system_zones.size} zones.\n"
      zone_vent = false
    end

    # create WSHPs
    wshps = std.model_add_water_source_hp(model, system_zones, hx_loop, ventilation: zone_vent)
    final_cond_message << "Building HVAC replaced with #{wshps.size} Zone-level Water-Source Heat Pumps.\n"

    # apply standard efficiency
    apply_standard_efficiency(model, climate_zone, std)


    # doas
    if doas_bool 
      model.getAirLoopHVACs.each do |ahu|
        ahu.supplyComponents.each do |comp|
          if comp.to_CoilCoolingDXTwoSpeed.is_initialized
            # DX cool
            comp = comp.to_CoilCoolingDXTwoSpeed.get
            comp.setRatedHighSpeedCOP(doas_cool_cop)
            comp.setRatedLowSpeedCOP(doas_cool_cop)
          elsif comp.to_CoilHeatingDXSingleSpeed.is_initialized
            # DX heat
            comp = comp.to_CoilHeatingDXSingleSpeed.get
            comp.setRatedCOP(doas_heat_cop)
          elsif comp.to_CoilHeatingGas.is_initialized
            # Gas Furnace
            comp = comp.to_CoilHeatingGas.get
            comp.setGasBurnerEfficiency(doas_heat_cop)
          elsif comp.to_CoilHeatingElectric.is_initialized
            # Electric Resistance
            comp = comp.to_CoilHeatingElectric.get
            comp.setEfficiency(doas_heat_cop)
          elsif comp.to_AirLoopHVACUnitarySystem.is_initialized
            # WSHP
            comp = comp.to_AirLoopHVACUnitarySystem.get
            if comp.heatingCoil.is_initialized
              htg_coil = comp.heatingCoil.get
              if htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
                htg_coil = htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
                htg_coil.setRatedHeatingCoefficientofPerformance(doas_heat_cop)
              end
            end
            if comp.coolingCoil.is_initialized
              clg_coil = comp.coolingCoil.get
              if clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
                clg_coil = clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
                clg_coil.setRatedCoolingCoefficientofPerformance(doas_cool_cop)
              end
            end
          end
        end
      end
    end

    # Zone WSHPs
    model.getZoneHVACWaterToAirHeatPumps.each do |hp|
      hcoil = hp.heatingCoil.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
      hcoil.setRatedHeatingCoefficientofPerformance(heat_cop)
      ccoil = hp.coolingCoil.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
      ccoil.setRatedCoolingCoefficientofPerformance(cool_cop)
    end


    # report final condition of model
    runner.registerFinalCondition(final_cond_message)

    # log_msgs_to_file(debug, "add_gshp_output")

    return true
  end
end

# register the measure to be used by the application
SCEReplaceExistingHVACWithGroundSourceHeatPumps.new.registerWithApplication
