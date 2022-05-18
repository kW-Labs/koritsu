# insert your copyright here

require 'json'
# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddSCETariffs < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'add SCE tariffs'
  end

  # human readable description
  def description
    return 'Creates EnergyPlus utility rate objects from rate information exported from OpenEI Utility Rate Database'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # resource path 
  RATE_LIB_PATH = File.join(File.dirname(__FILE__), "/resources/sce_usurdb.json")
  TARIFF_LIB_PATH = File.join(File.dirname(__FILE__), "/resources/tariffs.idf")

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # select tariff from list
    # rate_path = File.join(File.dirname(__FILE__), "/resources/sce_usurdb.json")
    # rate_arry = JSON.parse(File.read(RATE_LIB_PATH))
    # rate_names = OpenStudio::StringVector.new
    # rate_arry.each do |hsh|
    #   rate_names << hsh["name"]
    # end

    library = OpenStudio::Workspace::load(TARIFF_LIB_PATH).get
    lib_tariffs = library.getObjectsByType("UtilityCost_Tariff".to_IddObjectType)
    lib_tariff_hash = {}
    lib_tariffs.each do |obj|
      lib_tariff_hash[obj.name.get] = obj
    end

    lib_tariff_names = OpenStudio::StringVector.new
    lib_tariff_hash.sort.map do |k,v|
      lib_tariff_names << k
    end

    rate = OpenStudio::Measure::OSArgument.makeChoiceArgument('rate', lib_tariff_names, true)
    rate.setDisplayName("Select Rate to add")
    rate.setDescription("Rates are applied to electricity end-use")
    args << rate

    return args
  end

  def find_obj_by_field_lookup(workspace, obj_type, lookup_val, field_num)
    objs = workspace.getObjectsByType(obj_type.to_IddObjectType)
    unless objs.empty?
      objs.each do |obj|
        if obj.getString(field_num).get == lookup_val
          return obj
        end
      end
    end
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    rate = runner.getStringArgumentValue('rate', user_arguments)

    # check argument
    if rate.nil? || rate == ""
      runner.registerError("Empty rate name entered")
      return false
    end

    # # parse rate information 
    # rate_arry = JSON.parse(File.read(RATE_LIB_PATH), :symbolize_names => true)
    # rate = rate_arry.find {|x| x[:name] == rate_name}
    # desc = rate[:description]
    # # these set demand limits 
    # peak_kw_cap_min = rate[:peakkwcapacitymin]
    # peak_kw_cap_max = rate[:peakkwcapacitymax]
    
    # # crete demand schedule
    # demand_wkdy_sch = rate[:demandweekdayschedule]
    # wkdy_start_mont
    # demand_wkdy_sch.each do |month|
    #   month.each do |hour|

    # demand_wknd_sch = rate[:demandweekendschedule]
    
    # # make type limits object
    # new_object_string = "
    # ScheduleTypeLimits,
    #   number, !- Name
    #   0,                                      !- Lower Limit Value {BasedOnField A3}
    #   4,                                      !- Upper Limit Value {BasedOnField A3}
    #   DISCRETE;                               !- Numeric Type
    #   "
    # type_limits = workspace.addObject(OpenStudio::IdfObject.load(new_object_string).get).get

    # array to hold objects to add
    objs = []
    # load idf
    library = OpenStudio::Workspace::load(TARIFF_LIB_PATH).get
    lib_tariff = library.getObjectByTypeAndName("UtilityCost_Tariff".to_IddObjectType, rate)
    if lib_tariff.is_initialized
      lib_tariff = lib_tariff.get
      objs << lib_tariff
    else 
      runner.registerError("Could not find UtilityCost:Tariff object #{rate} in library idf.")
      return false
    end

    # find schedules
    if lib_tariff.getString(5).is_initialized
      tou_sch_name = lib_tariff.getString(5).get
      tou_sch = library.getObjectByTypeAndName("Schedule_Compact".to_IddObjectType, tou_sch_name)
      if tou_sch.is_initialized and tou_sch.get.getString(1).is_initialized
        objs << tou_sch.get
        stl_name = tou_sch.get.getString(1).get
        stl = library.getObjectByTypeAndName("ScheduleTypeLimits".to_IddObjectType, stl_name).get
        unless objs.include? stl
          objs << stl
        end
      end
    end
    if lib_tariff.getString(6).is_initialized
      seas_sch_name = lib_tariff.getString(6).get
      seas_sch = library.getObjectByTypeAndName("Schedule_Compact".to_IddObjectType, seas_sch_name)
      if seas_sch.is_initialized and seas_sch.get.getString(1).is_initialized
        objs << seas_sch.get
        stl_name = seas_sch.get.getString(1).get
        stl = library.getObjectByTypeAndName("ScheduleTypeLimits".to_IddObjectType, stl_name).get
        unless objs.include? stl
          objs << stl
        end
      end
    end

    #
    uc_types = ["UtilityCost_Qualify", "UtilityCost_Charge_Simple", "UtilityCost_Charge_Block", "UtilityCost_Ratchet", "UtilityCost_Variable", "UtilityCost_Computation"]
    uc_types.each do |type|
      obj = find_obj_by_field_lookup(library, type, rate, 1)
      unless obj.nil?
        objs << obj
      end
    end

    require 'pp'
    pp objs

    objs.each do |obj|
      workspace.addObject(obj)
    end
    runner.registerFinalCondition("#{objs.size} objects added to model #{rate}")
    

    

    return true
  end
end

# register the measure to be used by the application
AddSCETariffs.new.registerWithApplication
