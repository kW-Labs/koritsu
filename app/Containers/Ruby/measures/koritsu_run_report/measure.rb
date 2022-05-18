# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'json'
require 'date'
require 'csv'

# start the measure
class KoritsuRunReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'koritsu run report'
  end

  # human readable description
  def description
    return ''
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    run_name = OpenStudio::Measure::OSArgument.makeStringArgument('run_name', true)
    run_name.setDescription("Koritsu Alternative Name")
    args << run_name

    # California climate zone options for CO2 reporting
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

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    # this measure does not produce machine readable outputs with registerValue, return an empty list

    return outs
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # To use the built-in error checking we need the model...
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # timeseries data
    # outdoor air temp
    result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Drybulb Temperature,Hourly;').get


    # todo: this can generate output:meters for all end-uses and all fuel types, but will be excessive. 
    # fuel_types = ["Electricity", "NaturalGas"]
    # category_strs = []
    # OpenStudio::EndUseCategoryType.getValues.each do |category_type|
    #   category_str = OpenStudio::EndUseCategoryType.new(category_type).valueDescription
    #   category_strs << category_str
    # end
      
    # TODO: Outdoor Air
    # TODO: CO2

    # end-use meters
    # total electricity
    result << OpenStudio::IdfObject.load('Output:Meter,Electricity:Facility,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Meter,ElectricityPurchased:Facility,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Meter,ElectricitySurplusSold:Facility,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Meter,ElectricityNet:Facility,hourly;').get
    # total nat gas
    result << OpenStudio::IdfObject.load('Output:Meter,NaturalGas:Facility,hourly;').get
    # custom meter for lighting and plugs electricity
    result << OpenStudio::IdfObject.load('Meter:Custom,LightsAndPlugs,Electricity,,InteriorLights:Electricity,,ExteriorLights:Electricity,,InteriorEquipment:Electricity,,ExteriorEquipment:Electricity;').get
    result << OpenStudio::IdfObject.load('Output:Meter,LightsAndPlugs,hourly;').get
    # custom meter for equipment gas
    result << OpenStudio::IdfObject.load('Meter:Custom,GasEquipment,NaturalGas,,InteriorEquipment:NaturalGas,,ExteriorEquipment:NaturalGas;').get
    result << OpenStudio::IdfObject.load('Output:Meter,GasEquipment,hourly;').get
    resources = ["Electricity", "NaturalGas"]
    uses = ["Cooling", "Heating", "Fans", "Pumps", "HeatRejection", "HeatRecovery", "WaterSystems", "Refrigeration"]
    resources.each do |source|
      uses.each do |use|    
        result << OpenStudio::IdfObject.load("Output:Meter,#{use}:#{source},hourly;").get
      end
    end
    # building electricity - internal loads (lighting, equipment)
    result << OpenStudio::IdfObject.load('Output:Meter,Electricity:Building,hourly;').get
    # building nat gas - internal loads (equipment)
    result << OpenStudio::IdfObject.load('Output:Meter,NaturalGas:Building,hourly;').get
    # hvac electricity - cooling/heating/fans
    result << OpenStudio::IdfObject.load('Output:Meter,Electricity:HVAC,hourly;').get
    # hvac gas - heating
    result << OpenStudio::IdfObject.load('Output:Meter,NaturalGas:HVAC,hourly;').get
    # plant electricity - pumps/chiller
    result << OpenStudio::IdfObject.load('Output:Meter,Electricity:Plant,hourly;').get
    # plant natgas - boiler
    result << OpenStudio::IdfObject.load('Output:Meter,NaturalGas:Plant,hourly;').get

    # load factor table
    result << OpenStudio::IdfObject.load('Output:Table:Monthly,Load Factor Calculation Table,2,ElectricityNet:Facility,SumOrAverage,ElectricityNet:Facility,Maximum;').get

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # get measure arguments
    run_name = runner.getStringArgumentValue('run_name', user_arguments)

    # load sql file
    sql_file = runner.lastEnergyPlusSqlFile
    if sql_file.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sql_file = sql_file.get
    # model.setSqlFile(sql_file)

    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql_file.availableEnvPeriods.each do |env_pd|
      env_type = sql_file.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
          break
        end
      end
    end

    # create hash to store all information
    run_data = {}
    run_data["name"] = run_name
    
    ###################################################################################################
    # create building summary
    summary_arry = []
    warnings = []

    # total building area
    name = "total_building_area"
    display = 'Total Building Area (ft^2)'
    source_units = 'm^2'
    target_units = 'ft^2'
    total_area = nil
    total_area_si = nil

    query = 'SELECT Value FROM tabulardatawithstrings WHERE '
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Building Area' and "
    query << "RowName='Total Building Area' and "
    query << "ColumnName='Area' and "
    query << "Units='m2';"
    query_result = sql_file.execAndReturnFirstDouble(query)
    if query_result.empty?
      warnings << "Did not find value for total building area.\n"
    else
      total_area_si = query_result.get
      total_area = OpenStudio.convert(total_area_si, source_units, target_units).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units, "value"=>total_area}

    # total EUI
    name = "total_site_eui"
    display = 'Total Site EUI (kBtu/ft^2)'
    source_units = 'GJ/m^2'
    target_units = 'kBtu/ft^2'
    eui = nil

    query_result = sql_file.totalSiteEnergy
    
    if query_result.empty?
      warnings << "Did not find value for total site energy. Cannot calculate Total EUI.\n"
    elsif total_area_si.nil? || total_area_si == 0.0
      warnings << "Cannot calculate Total EUI.\n"
    else
      eui = query_result.get / total_area_si
      eui = OpenStudio.convert(eui, source_units, target_units).get
    end
    summary_arry << {"name"=>name, "display_name"=> display, "units"=>target_units, "value"=> eui}


    #peak electric demand kwh
    name = "total_elec_demand_kw"
    display = "Total Electric Demand (kW)"
    source_units = "W"
    target_units = "kW"
    total_demand = nil

    query = "SELECT Value FROM TabularDataWithStrings "
    query << "WHERE ReportName='BUILDING ENERGY PERFORMANCE - ELECTRICITY PEAK DEMAND' "
    query << "AND ReportForString='Meter' "
    query << "AND TableName='Custom Monthly Report' "
    query << "AND ColumnName= 'ELECTRICITY:FACILITY {Maximum}' " #Note: string missing closing curly bracket - might have to correct query when this is fixed.
    query << "AND RowName='Maximum of Months'"

    query_result = sql_file.execAndReturnFirstDouble(query)
    if query_result.empty?
      warnings << "Did not find value for peak electric demand.\n"
    else
      total_demand = OpenStudio.convert(query_result.get,source_units, target_units).get
    end
    summary_arry << {"name"=>name, "display_name"=> display, "units"=>target_units, "value"=> total_demand}

    # purchased electric demand
    name = "purch_elec_demand_kw"
    display = "Purchased Electricity Peak Demand (kW)"
    source_units = "W"
    target_units = "kW"
    purch_demand = nil 

    query = "SELECT Value FROM TabularDataWithStrings "
    query << "WHERE ReportName='EnergyMeters' "
    query << "AND ReportForString='Entire Facility' "
    query << "AND TableName='Annual and Peak Values - Electricity' "
    query << "AND ColumnName='Electricity Maximum Value' "
    query << "AND RowName='ElectricityPurchased:Facility'"

    query_result = sql_file.execAndReturnFirstDouble(query)
    if query_result.empty?
      warnings << "Did not find value for peak electric demand.\n"
    else
      purch_demand = OpenStudio.convert(query_result.get,source_units, target_units).get
    end
    summary_arry << {"name"=>name, "display_name"=> display, "units"=>target_units, "value"=> purch_demand}

    # total site electricity
    name = "total_site_electricity_kwh"
    display = "Total Site Electricity (kWh)"
    source_units = "GJ"
    target_units_elec = "kWh"
    total_elec = nil
    query_result = sql_file.electricityTotalEndUses

    query_result = sql_file.execAndReturnFirstDouble(query)

    if query_result.empty?
      warnings << "Did not find value for #{display}.\n"
    else
      total_elec = OpenStudio.convert(query_result.get,source_units,target_units_elec).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units_elec,"value"=>total_elec}

    # total purchased electricity
    name = "purch_electric_energy_kwh"
    display = "Total Purchased Electricity (kWh)"
    source_units = "GJ"
    target_units = "kWh"
    purch_elec = nil

    query = "SELECT Value FROM TabularDataWithStrings "
    query << "WHERE ReportName='EnergyMeters' "
    query << "AND ReportForString='Entire Facility' "
    query << "AND TableName='Annual and Peak Values - Electricity' "
    query << "AND ColumnName='Electricity Annual Value' "
    query << "AND RowName='ElectricityPurchased:Facility'"

    query_result = sql_file.execAndReturnFirstDouble(query)

    if query_result.empty?
      warnings << "Did not find value for #{display}.\n"
    else
      purch_elec = OpenStudio.convert(query_result.get,source_units,target_units_elec).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units_elec,"value"=>purch_elec}

    # total site natural gas
    name = "total_site_gas_therm"
    display = "Total Site Gas (Therms)"
    target_units_gas = "therm"
    total_gas = nil
    query_result = sql_file.naturalGasTotalEndUses

    if query_result.is_initialized
      total_gas = OpenStudio.convert(query_result.get, source_units, target_units_gas).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units_gas,"value"=>total_gas}

    # total site district cooling 
    
    name = "total_site_district_cooling_mbtu"
    display = "Total Site District Cooling (MBtu)"
    dc_tot = nil
    target_units_purch = "MBtu" #million btu

    query_result = sql_file.districtCoolingTotalEndUses
    if query_result.is_initialized
      dc_tot = OpenStudio.convert(query_result.get, source_units, target_units_purch).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units_purch,"value"=>dc_tot}

    # total site district heating
    name = "total_site_district_heating_mbtu"
    display = "Total Site District Heating (MBtu)"
    dh_tot = nil

    query_result = sql_file.districtHeatingTotalEndUses
    if query_result.is_initialized
      dh_tot = OpenStudio.convert(query_result.get, source_units, target_units_purch).get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>target_units_purch,"value"=>dh_tot}

    # total annual utility cost
    name = "total_annual_utility_cost"
    display = "Total Annual Utility Cost ($)"
    units = "$"
    tot_cost = nil
    query_result = sql_file.annualTotalUtilityCost
    if query_result.is_initialized
      tot_cost = query_result.get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>units, "value"=>tot_cost}

    # annual energy costs by fuel type
    ['Electricity', 'Natural Gas', 'Other'].each do |fuel|
      fuel_name = fuel.downcase.gsub(' ','_')
      name = "total_annual_#{fuel_name}_cost"
      display = "Total Annual #{fuel} Cost ($)"
      cost = nil
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='Economics Results Summary Report' AND TableName='Annual Cost' AND ColumnName='#{fuel}' AND RowName='Cost'"
      query_result = sql_file.execAndReturnFirstDouble(query)
      if query_result.is_initialized        
        cost = query_result.get
      end
      summary_arry << {"name"=>name, "display_name"=>display, "units"=>units, "value"=>cost}
    end



    
    # total life cycle cost - total present value
    name = "total_life_cycle_cost"
    display = "Total Life Cycle Present Value ($)"
    units = "$"
    lc_cost = nil
    query = "SELECT Value FROM TabularDataWithStrings "
    query << "WHERE ReportName='Life-Cycle Cost Report' "
    query << "AND TableName='Present Value by Category' "
    query << "AND ColumnName='Present Value' "
    query << "AND RowName='Grand Total'"
    query_result = sql_file.execAndReturnFirstDouble(query)
    if query_result.is_initialized
      lc_cost = query_result.get
    end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>units, "value"=>lc_cost}

    # simple payback years - equals initial investment / annual savings, e.g. (proposed construction cost - baseline construction cost) / (proposed energy cost - baseline energy cost)
    # Since this calc requires knowlege of baseline costs, it will have to be calculated in the master script
    # To facilitate that, we will report the total nonrecurring cost (and total utility cost, above)
    name = "total_nonrecurring_cost"
    display = "Total NonRecurring Costs ($)"
    units = "$"
    
    col_name_query = "SELECT RowName FROM TabularDataWithStrings "
    col_name_query << "WHERE ReportName='Life-Cycle Cost Report' AND TableName='Present Value for Recurring, Nonrecurring and Energy Costs (Before Tax)' "
    col_name_query << "AND ColumnName='Kind' AND Value='Nonrecurring'"
    col_name_query_result = sql_file.execAndReturnVectorOfString(col_name_query)
    tot_nonrecurring_cost = 0
    if col_name_query_result.is_initialized
      col_name_query_result.get.each do |rowname|
        value_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='Life-Cycle Cost Report' AND TableName='Present Value for Recurring, Nonrecurring and Energy Costs (Before Tax)' "
        value_query << "AND RowName='#{rowname}' AND ColumnName='Cost'"
        value = sql_file.execAndReturnFirstDouble(value_query)
        if value.is_initialized
          tot_nonrecurring_cost += value.get
        end
      end
    else
      warnings << "No Nonrecurring costs found in model. Simple Payback will not be calculated.\n"
      
    end
    if tot_nonrecurring_cost == 0
      warnings << "No Nonrecurring costs found in model. Simple Payback will not be calculated.\n"
      tot_nonrecurring_cost = nil
    else
      summary_arry << {"name"=>name, "display_name"=>display, "units"=>units, "value"=>tot_nonrecurring_cost}
    end

    # TODO - calculate and report simple payback

    run_data["building_summary"] = {"data" => summary_arry, "warnings" => warnings}
    ###################################################################################################

    # Annual Overview Stacked Bar Chart
    annual_overview = {}
    # This reports annual energy consumption by end-use (sum of fuels)
    from_unit = "GJ"
    unit_hash = {"electricity"=>"kWh", "naturalGas"=>"Therm", "co2"=>"tons"}

    uses = ["Heating", "Cooling", "Interior Lighting", "Exterior Lighting", "Interior Equipment", "Exterior Equipment", "Fans", "Pumps", "Heat Rejection", "Humidification", "Heat Recovery", "Water Systems", "Refrigeration", "Generators"]

    #TODO - get end-use CO2
    ["electricity","naturalGas"].each do |fuel|
      annual_overview["#{fuel}"] = {}
      annual_overview["#{fuel}"]["unit"] = unit_hash["#{fuel}"]
      #initialize hash with keys from uses array
      annual_overview["#{fuel}"]["data"] = Hash[uses.map {|x| [x,0]}]
      uses.each do |use|
        method_name = "#{fuel}#{use.gsub(" ","")}"
        if sql_file.respond_to?(method_name)
          val = sql_file.method(method_name).call
          if !val.empty?
            val = OpenStudio.convert(val.get, from_unit, unit_hash["#{fuel}"]).get
            annual_overview["#{fuel}"]["data"]["#{use}"] += val
          end
        end
      end
    end

    # pv produced energy
    pv_elec = nil
    query = "SELECT Value FROM TabularDataWithStrings "
    query << "WHERE ReportName='EnergyMeters' "
    query << "AND ReportForString='Entire Facility' "
    query << "AND TableName='Annual and Peak Values - Electricity' "
    query << "AND ColumnName='Electricity Annual Value' "
    query << "AND RowName='ElectricityProduced:Facility'"

    query_result = sql_file.execAndReturnFirstDouble(query)

    if query_result.empty?
      warnings << "Did not find value for PV-produced electricity.\n"
    else
      pv_elec = OpenStudio.convert(query_result.get,from_unit,"kWh").get
      annual_overview["electricity"]["data"]["PV Produced"] = -pv_elec
    end

    
    run_data["annual_overview"] = annual_overview
    ###################################################################################################

    # timeseries data
    # timeseries_data = [
    #   {"name"=> "elec_facility", "display_name"=> "Total Electricity","units"=> "kW", "meter_name"=>"Electricity:Facility", "description"=>"Hourly Average Electricity Demand"},
    #   {"name"=> "elec_building", "display_name"=> "Internal Electricity","units"=> "kW", "meter_name"=>"Electricity:Building", "description"=>"Hourly Average Internal Electricity Demand (includes Lights, Plug Loads and Elevators)"},
    #   # {"name"=> "elec_hvac", "display_name"=> "HVAC Electricity","units"=> "kW", "meter_name"=>"Electricity:HVAC", "description"=>"Hourly Average HVAC Demand (including Fans, DX Coils)."},
    #   # {"name"=> "elec_plant", "display_name"=> "Plant Electricity","units"=> "kW", "meter_name"=>"Electricity:Plant", "description"=>"Hourly Average Plant Demand (including Pumps, Chillers and Cooling Towers)"},
    #   # {"name"=> "gas_facility", "display_name"=> "Total Natural Gas","units"=> "Btu", "meter_name"=>"NaturalGas:Facility", "description"=>"Hourly Average Natural Gas Demand"},
    #   # {"name"=> "gas_building", "display_name"=> "Internal Natural Gas","units"=> "Btu", "meter_name"=>"NaturalGas:Building", "description"=>"Hourly Average Internal Natural Gas Demand (includes Lights, Plug Loads and Elevators)"},
    #   # {"name"=> "gas_hvac", "display_name"=> "HVAC Natural Gas","units"=> "Btu", "meter_name"=>"NaturalGas:HVAC", "description"=>"Hourly Average HVAC Demand (including Air System Furnace)."},
    #   # {"name"=> "gas_plant", "display_name"=> "Plant Natural Gas","units"=> "Btu", "meter_name"=>"NaturalGas:Plant", "description"=>"Hourly Average Plant Demand (including Pumps, Chillers and Cooling Towers)"},
    # ]

    possible_timeseries = [
      {"name"=> "elec_facility", "display_name"=> "Total Electricity","units"=> "kW", "meter_name"=>"Electricity:Facility", "description"=>"Hourly Average Electricity Demand"},
      {"name"=> "gas_facility", "display_name"=> "Total Natural Gas","units"=> "Btu", "meter_name"=>"NaturalGas:Facility", "description"=>"Hourly Average Natural Gas Demand"},
      {"name"=> "elec_lightsequip", "display_name"=>"Total Lighting and Electric Equipment", "units"=>"kW", "meter_name"=> "LIGHTSANDPLUGS", "description"=>"Hourly Total Interior and Exterior Lighting and Electric Equipment Demand (e.g. plug loads)"},
      {"name"=> "gas_equip", "display_name"=> "Total Natural Gas Equipment", "units"=> "Btu", "meter_name"=> "GASEQUIPMENT", "description"=> "Hourly Total Interior Gas Equipment Demand"}
    ]
    
    #populate the remaining possible timeseries data
    resources = {"Electricity"=>"elec", "NaturalGas"=>"gas"}
    uses = {"Cooling"=>"clg", "Heating"=>"htg", "Fans"=>"fans", "Pumps"=>"pumps", "HeatRejection"=>"heatrej", "HeatRecovery"=>"heatrec", "WaterSystems"=>"watersys", "Refrigeration"=>"ref"}
    resources.each do |source,source_abrev|
      uses.each do |use, use_abrev|
        ts_hash = {}
        source_split = source.gsub(/(?<=[[:alpha:]])(?=[[:upper:]])/," ")
        use_split = use.gsub(/(?<=[[:alpha:]])(?=[[:upper:]])/," ")
        ts_hash["name"] = "#{source_abrev}_#{use_abrev}"
        ts_hash["display_name"] = "#{use_split} #{source_split}"
        ts_hash["meter_name"] = "#{use}:#{source}"
        ts_hash["description"] = "Hourly Average #{use_split} #{source_split} Demand"
        if source == "Electricity"
          ts_hash["units"] = "kW"
        else
          ts_hash["units"] = "Btu"
        end
        possible_timeseries << ts_hash
      end
    end


    reporting_frequency = "Hourly"
    
    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql_file.availableEnvPeriods.each do |env_pd|
      env_type = sql_file.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
          break
        end
      end
    end

    meter_names = sql_file.availableVariableNames(ann_env_pd, reporting_frequency)
    puts meter_names
    
    meters = ["Electricity:Facility", "NaturalGas:Facility", "Electricity:Building", "NaturalGas:Building", "NaturalGas:HVAC", "Electricity:Plant", "NaturalGas:Plant"]

    # create date array
    time_strs = []
    start_time = DateTime.new(2021,1,1,0,0,0)
    time_format = time_f = "%Y-%m-%d %H:%M:%S"
    (8760).times.each do |i|
      time_strs << (start_time + i/24r).strftime(time_format)
    end

    timeseries_data = []
    
    # only query for timeseries available in sql fil
    available_ts = sql_file.availableTimeSeries
    possible_timeseries.each do |ts|
      if available_ts.include? ts["meter_name"]
        timeseries_data << ts
      end
    end
    
    first_report_date = OpenStudio::DateTime.new(OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1,2021))
    interval_len = OpenStudio::Time.new(0,1,0,0)

    # get co2 emissions data as timeseries
    # assign the user inputs to variables
    climate_zone = runner.getStringArgumentValue("climate_zone",user_arguments).to_i

    elec_csv_path = "#{__dir__}/resources/METRIC_008_20180919_LR_Emissions-elec_nonres_30yr.csv"
    gas_csv_path = "#{__dir__}/resources/METRIC_008_20180919_LR_Emissions-gas_nonres_30yr.csv"
    
    # load CSVs and extract column
    if File.exist?(elec_csv_path)
      elec_data = CSV.read(elec_csv_path)
    else runner.registerError("Could not find CSV file at #{elec_csv_path}")
      return false
    end
    
    if File.exist?(gas_csv_path)
        gas_data = CSV.read(gas_csv_path)
    else runner.registerError("Could not find CSV file at #{gas_csv_path}")
      return false
    end

    # transpose and select the column corresponding to cz
    elec_factors = elec_data.transpose[(climate_zone.to_i-1)] # tonnes CO2/kWh
    gas_factors = gas_data.transpose[(climate_zone.to_i-1)] # tonnes CO2/therm

    tonnes_to_lbs = 2204.62
    # create OpenStudio Timeseries for each file
    elec_factor_vals = OpenStudio::Vector.new
    elec_factors.each{|i| elec_factor_vals << i.to_f * tonnes_to_lbs}
    # elec_factor_ts = OpenStudio::TimeSeries.new(first_report_date, interval_len, elec_factor_vals, "lbs CO2/kWh")

    gas_factor_vals = OpenStudio::Vector.new
    gas_conversion = OpenStudio.convert(1,"1/therm","1/Btu").get
    gas_factors.each{|i| gas_factor_vals << i.to_f * gas_conversion * tonnes_to_lbs}
    # gas_factor_ts = OpenStudio::TimeSeries.new(first_report_date, interval_len, gas_factor_vals, "lbs CO2/Btu")


    # get all energy meter timeseries and add to data output
    co2_data_arry = []
    elec_total_co2 = 0
    gas_total_co2 = 0
    timeseries_data.each do |h|
      meter_name = h["meter_name"]
      h["units"] == "kW" ? to_unit = "kWh" : to_unit = h["units"]
      
      # create co2 data object from energy meter
      co2_h = {}
      co2_h["name"] = h["name"] + "_co2"
      co2_h["display_name"] = h["display_name"] + " CO2"
      co2_h["units"] = "lbs"
      co2_h["meter_name"] = h["meter_name"] + "_co2"
      co2_h["description"] = h["description"].gsub("Demand", "Equivalent CO2 Emissions")

      ts_new = nil
      timeseries = sql_file.timeSeries(ann_env_pd, reporting_frequency, meter_name,"")
      if !timeseries.empty?
        timeseries = timeseries.get
        from_units = timeseries.units

        conversion = OpenStudio.convert(1,from_units, to_unit).get
        # convert timeseries
        ts_new = timeseries * conversion
        # collect ts values
        ts_vals = []
        ts_new.values.each {|v| ts_vals << v}
        # zip with time strings
        data = time_strs[0..ts_vals.size].zip(ts_vals)
        h["data"] = data

        # create CO2 data and add to co2 object
        if h["name"].include? "elec_"
          emissions_vals = ts_vals.each_with_index.map{|x,i| x*elec_factor_vals[i]}
        else
          emissions_vals = ts_vals.each_with_index.map{|x,i| x*gas_factor_vals[i]}
        end

        # get total facility meter emissions
        if h["name"] == "elec_facility"
          elec_total_co2 = emissions_vals.sum
        end
        if h["name"] == "gas_facility"
          gas_total_co2 = emissions_vals.sum
        end

        # zip with time strings
        co2_data = time_strs[0..emissions_vals.size].zip(emissions_vals)
        co2_h["data"] = co2_data
      else
        h["data"] = nil
        co2_h["data"] = nil
        h["warnings"] = ["No data found for meter: #{meter_name}.\n"]
        co2_h["warnings"] = ["No data found for energy metere: #{meter_name}. Could not calculate emisisons for meter.\n"]
      end
      co2_data_arry << co2_h
    end

    run_data["timeseries"] = timeseries_data + co2_data_arry
    
    # calculate total CO2 emissions
    co2_total_lb = elec_total_co2 + gas_total_co2
    
    # total annual CO2 mass
    name = "co2_emissions_tons"
    display = "Source CO2 Emissions (tons)"
    units = "tons"
    co2_tons = co2_total_lb / 2000.0
    # query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND TableName='Annual and Peak Values - Other by Weight/Mass' AND ColumnName='Annual Value' AND RowName='CO2:Facility'"
    # query_result = sql_file.execAndReturnFirstDouble(query)
    # if query_result.is_initialized
    #   query_result = query_result.get
    #   co2_tons = OpenStudio.convert(query_result,"kg","lb_m").get / 2000.0
    # end
    summary_arry << {"name"=>name, "display_name"=>display, "units"=>units, "value"=>co2_tons}

    

    ###################################################################################################

    # close the sql file
    sql_file.close

    # try saving result hash
    out_path = './report.json'
    File.open(out_path,'w') do |file|
      file << JSON.pretty_generate(run_data)
      # make sure data is written to disk one way or another
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    return true
  end
end

# register the measure to be used by the application
KoritsuRunReport.new.registerWithApplication
