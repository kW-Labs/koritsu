# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEEnvironmentalImpactFactors < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Environmental Impact Factors'
  end

  # human readable description
  def description
    return 'Adds Output:EnvironmentalImpactFactors, EnvironmentalImpactFactors, and FuelFactors objects. Electricity FuelFactors imported from hourly schedule. All others set to standard values.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # TODO
    # make argument for 30 yr or 15 yr impact factors

		# California climate zone options
		climate_zones = OpenStudio::StringVector.new
		climate_zones << "1"
		climate_zones << "2"
		climate_zones << "3"
		climate_zones << "4"
		climate_zones << "5"
		climate_zones << "6"
		climate_zones << "7"
		climate_zones << "8"
		climate_zones << "9"
		climate_zones << "10"
		climate_zones << "11"
		climate_zones << "12"
		climate_zones << "13"
		climate_zones << "14"
		climate_zones << "15"
		climate_zones << "16"
		climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("climate_zone",climate_zones,true)
		climate_zone.setDisplayName("Select California Climate Zone:")
		climate_zone.setDefaultValue("3")
		args << climate_zone

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    climate_zone = runner.getStringArgumentValue("climate_zone",user_arguments)

    
    # TDV emission factors come from .csv files in the resources directory
    # they are organized with each column as a climate zone (index = cz_number - 1)
    # transpose the array so each row is a climate zone

    tdv_elec_csv = CSV.read("#{File.dirname(__FILE__)}/resources/METRIC_008_20180919_LR_Emissions-elec_nonres_30yr.csv"); nil
    tdv_elec_csv = tdv_elec_csv.transpose

    tdv_gas_csv = CSV.read("#{File.dirname(__FILE__)}/resources/METRIC_008_20180919_LR_Emissions-gas_nonres_30yr.csv"); nil
    tdv_gas_csv = tdv_gas_csv.transpose

    tdv_elec_factors = tdv_elec_csv[(climate_zone.to_i-1)]
    tdv_gas_factors = tdv_gas_csv[(climate_zone.to_i-1)]
    data = {"Electric" => tdv_elec_factors, "Gas" => tdv_gas_factors}
  
    # hash to store schedules
    schedules = {}

    # create dummy model
    # use model methods to create schedule
    model = OpenStudio::Model::Model.new

    # import csv to schedule:interval
    data.each do |key, row|
      num_vals = row.length
      schedule_values = OpenStudio::Vector.new(num_vals, 0.0)
      row.each_with_index do |val, i|
        schedule_values[i] = val.to_f
      end

      # set hourly interval 
      interval = OpenStudio::Time.new(0,1,0)
    
      # make scheudle
      startDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1),1)
      timeseries = OpenStudio::TimeSeries.new(startDate, interval, schedule_values, 'unitless')
      schedule = OpenStudio::Model::ScheduleInterval::fromTimeSeries(timeseries, model)
      if schedule.empty?
        runner.registerError("Unable to make schedule from file")
        return false
      end
      schedule = schedule.get
      schedule.setName("#{key} Emission Factor Schedule")
      # add to hash
      schedules[key] = schedule
    end

    # translate schedules to ws objects
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    ws = ft.translateModel(model)

    # get schedules
    sch_objs = ws.getObjectsByType("Schedule:Compact".to_IddObjectType)
    
    # add to workspace
    sch_objs.each {|o| workspace.addObject(o)}

    # create new EnvironmentalImpactFactors and FuelFactor objects
    obj_strings = []

    obj_strings << "
    Output:EnvironmentalImpactFactors,
      Monthly;                 !- Reporting Frequency"

    obj_strings << "
    EnvironmentalImpactFactors,
      0.663,                   !- District Heating Efficiency
      4.18,                    !- District Cooling COP {W/W}
      0.585,                   !- Steam Conversion Efficiency
      80.7272,                 !- Total Carbon Equivalent Emission Factor From N2O {kg/kg}
      6.2727,                  !- Total Carbon Equivalent Emission Factor From CH4 {kg/kg}
      0.2727;                  !- Total Carbon Equivalent Emission Factor From CO2 {kg/kg}
    "

    # current data is in tonnes CO2e/kWh = 277778.0 g/MJ
    elec_converter = 277778.0


    obj_strings << "
    FuelFactors,
      Electricity,             !- Existing Fuel Resource Name
      kg,                      !- Units of Measure
      ,                        !- Energy per Unit Factor
      3.546,                   !- Source Energy Factor {J/J}
      ,                        !- Source Energy Schedule Name
      #{elec_converter},               !- CO2 Emission Factor {g/MJ}           <----- set to 1
      Electric Emission Factor Schedule,                        !- CO2 Emission Factor Schedule Name    <----- set schedule
      1.186E-01,               !- CO Emission Factor {g/MJ}
      ,                        !- CO Emission Factor Schedule Name
      7.472E-01,               !- CH4 Emission Factor {g/MJ}
      ,                        !- CH4 Emission Factor Schedule Name
      6.222E-01,               !- NOx Emission Factor {g/MJ}
      ,                        !- NOx Emission Factor Schedule Name
      8.028E-03,               !- N2O Emission Factor {g/MJ}
      ,                        !- N2O Emission Factor Schedule Name
      1.872E+00,               !- SO2 Emission Factor {g/MJ}
      ,                        !- SO2 Emission Factor Schedule Name
      0.0,                     !- PM Emission Factor {g/MJ}
      ,                        !- PM Emission Factor Schedule Name
      1.739E-02,               !- PM10 Emission Factor {g/MJ}
      ,                        !- PM10 Emission Factor Schedule Name
      0.0,                     !- PM2.5 Emission Factor {g/MJ}
      ,                        !- PM2.5 Emission Factor Schedule Name
      0.0,                     !- NH3 Emission Factor {g/MJ}
      ,                        !- NH3 Emission Factor Schedule Name
      1.019E-02,               !- NMVOC Emission Factor {g/MJ}
      ,                        !- NMVOC Emission Factor Schedule Name
      5.639E-06,               !- Hg Emission Factor {g/MJ}
      ,                        !- Hg Emission Factor Schedule Name
      2.778E-05,               !- Pb Emission Factor {g/MJ}
      ,                        !- Pb Emission Factor Schedule Name
      0.4309556,               !- Water Emission Factor {L/MJ}
      ,                        !- Water Emission Factor Schedule Name
      0,                       !- Nuclear High Level Emission Factor {g/MJ}
      ,                        !- Nuclear High Level Emission Factor Schedule Name
      0;                       !- Nuclear Low Level Emission Factor {m3/MJ}
    "



    # emissions factors are metric ton / therm = 9480.43 g/MJ
    gas_converter = 9480.43

    obj_strings << "
    ! Deru and Torcellini 2007
    ! Source Energy and Emission Factors for Energy Use in Buildings
    ! NREL/TP-550-38617
    ! source factor and Higher Heating Values from Table 5
    ! post-combustion emission factors for boiler from Table 9 (with factor of 1000 correction for natural gas)

    FuelFactors,
      NaturalGas,              !- Existing Fuel Resource Name
      m3,                      !- Units of Measure
      37631000,                !- Energy per Unit Factor
      1.092,                   !- Source Energy Factor {J/J}
      ,                        !- Source Energy Schedule Name
      #{gas_converter},                !- CO2 Emission Factor {g/MJ}
      Gas Emission Factor Schedule,                        !- CO2 Emission Factor Schedule Name
      3.99E-02,                !- CO Emission Factor {g/MJ}
      ,                        !- CO Emission Factor Schedule Name
      1.06E-03,                !- CH4 Emission Factor {g/MJ}
      ,                        !- CH4 Emission Factor Schedule Name
      4.73E-02,                !- NOx Emission Factor {g/MJ}
      ,                        !- NOx Emission Factor Schedule Name
      1.06E-03,                !- N2O Emission Factor {g/MJ}
      ,                        !- N2O Emission Factor Schedule Name
      2.68E-04,                !- SO2 Emission Factor {g/MJ}
      ,                        !- SO2 Emission Factor Schedule Name
      0.0,                     !- PM Emission Factor {g/MJ}
      ,                        !- PM Emission Factor Schedule Name
      3.59E-03,                !- PM10 Emission Factor {g/MJ}
      ,                        !- PM10 Emission Factor Schedule Name
      0.0,                     !- PM2.5 Emission Factor {g/MJ}
      ,                        !- PM2.5 Emission Factor Schedule Name
      0,                       !- NH3 Emission Factor {g/MJ}
      ,                        !- NH3 Emission Factor Schedule Name
      2.61E-03,                !- NMVOC Emission Factor {g/MJ}
      ,                        !- NMVOC Emission Factor Schedule Name
      1.11E-07,                !- Hg Emission Factor {g/MJ}
      ,                        !- Hg Emission Factor Schedule Name
      2.13E-07,                !- Pb Emission Factor {g/MJ}
      ,                        !- Pb Emission Factor Schedule Name
      0,                       !- Water Emission Factor {L/MJ}
      ,                        !- Water Emission Factor Schedule Name
      0,                       !- Nuclear High Level Emission Factor {g/MJ}
      ,                        !- Nuclear High Level Emission Factor Schedule Name
      0;                       !- Nuclear Low Level Emission Factor {m3/MJ}
    "
    # hourly outputs
    obj_strings << "Output:Variable,*,Environmental Impact Electricity Source Energy,hourly; !- HVAC Sum [J]"
    obj_strings << "Output:Variable,*,Environmental Impact Electricity CO2 Emissions Mass,hourly; !- HVAC Sum [kg]"
    obj_strings << "Output:Variable,*,Environmental Impact NaturalGas CO2 Emissions Mass,hourly; !- HVAC Sum [kg]"

    # add all of the strings to workspace to create IDF objects
    obj_strings.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end

    return true
  end
end

# register the measure to be used by the application
SCEEnvironmentalImpactFactors.new.registerWithApplication
