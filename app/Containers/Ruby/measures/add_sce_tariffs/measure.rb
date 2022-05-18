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
    return 'This measure will add pre defined tariffs from IDF files in the resrouce directory for this measure. Adapted from NREL \"Tariff Selection - Generic\" measure.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure works by cloning objects in from an external file into the current IDF file. Change functionality by changing the resource files. This measure may also adjust the simulation timestep.'
  end

  # resource path 
  RATE_LIB_PATH = File.join(File.dirname(__FILE__), "/resources/sce_usurdb.json")
  TARIFF_LIB_PATH = File.join(File.dirname(__FILE__), "/resources/tariffs.idf")

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    option_chs = OpenStudio::StringVector.new
    option_chs << "Option D"
    option_chs << "Option E"

    option = OpenStudio::Measure::OSArgument::makeChoiceArgument('option', option_chs, true)
    option.setDisplayName("Select SCE TOU Tariff Option to Apply")
    option.setDescription("The correct TOU rated will be applied based on building's peak demand")
    option.setDefaultValue("Option D")
    args << option

    # # possible tariffs
    # meters = {}

    # # list files in resources directory and bin by meter of tariff object
    # tariff_files = Dir.entries("#{File.dirname(__FILE__)}/resources")
    # tariff_files.each do |tar|
    #   next if !tar.include?('.idf')

    #   # load the idf file containing the electric tariff
    #   tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{tar}")
    #   tar_file = OpenStudio::IdfFile.load(tar_path)

    #   # in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
    #   # below is a temporary workaround for this before issuing an error.
    #   if tar_file.empty?
    #     tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{tar}")
    #     tar_file = OpenStudio::IdfFile.load(tar_path)
    #   end

    #   if tar_file.empty?
    #     puts "Unable to find the file #{tar}"
    #   else
    #     tar_file = tar_file.get

    #     # get the tariff object and the requested meter
    #     tariff_object = tar_file.getObjectsByType('UtilityCost:Tariff'.to_IddObjectType)
    #     if tariff_object.size > 1
    #       puts "Only expected one tariff object in #{tar} but got #{tariff_object.size}"
    #     elsif tariff_object == 0
    #       puts "Expected on tariff object in #{tar} but got #{tariff_object.size}"
    #     else
    #       tariff_name = tariff_object[0].getString(0).get
    #       tariff_meter = tariff_object[0].getString(1).get
    #     end

    #     # populate hash with tariff object
    #     meters[{ file_name: tar.gsub('.idf', ''), obj_name: tariff_name }] = tariff_meter

    #   end
    # end

    # # make an argument for each meter value found in the hash
    # meters.values.uniq.each do |meter|
    #   choices = meters.select { |key, value| value == meter }

    #   # make a choice argument for tariff
    #   chs = []
    #   chs_display = []
    #   choices.each do |k, v|
    #     chs << k[:file_name]
    #     chs_display << k[:obj_name]
    #   end
    #   # TODO: - these will need to be unique names
    #   tar = OpenStudio::Measure::OSArgument.makeChoiceArgument(meter, chs, chs_display, true)
    #   tar.setDisplayName("Select a Tariff for #{meter}.")
    #   tar.setDefaultValue(chs[0])
    #   args << tar
    # end

    return args
  end

  # # create variables in run from user arguments
  # def createRunVariables(runner, model, user_arguments, arguments)
  #   result = {}

  #   error = false
  #   # use the built-in error checking
  #   unless runner.validateUserArguments(arguments, user_arguments)
  #     error = true
  #     runner.registerError('Invalid argument values.')
  #   end

  #   option = runner.getStringArgumentValue("option", user_arguments)

  #   user_arguments.each do |argument|
  #     # get argument info
  #     arg = user_arguments[argument]
  #     arg_type = arg.print.lines($/)[1]

  #     # create argument variable
  #     if arg_type.include? 'Double, Required'
  #       eval("result[\"#{arg.name}\"] = runner.getDoubleArgumentValue(\"#{arg.name}\", user_arguments)")
  #     elsif arg_type.include? 'Integer, Required'
  #       eval("result[\"#{arg.name}\"] = runner.getIntegerArgumentValue(\"#{arg.name}\", user_arguments)")
  #     elsif arg_type.include? 'String, Required'
  #       eval("result[\"#{arg.name}\"] = runner.getStringArgumentValue(\"#{arg.name}\", user_arguments)")
  #     elsif arg_type.include? 'Boolean, Required'
  #       eval("result[\"#{arg.name}\"] = runner.getBoolArgumentValue(\"#{arg.name}\", user_arguments)")
  #     elsif arg_type.include? 'Choice, Required'
  #       eval("result[\"#{arg.name}\"] = runner.getStringArgumentValue(\"#{arg.name}\", user_arguments)")
  #     else
  #       puts 'not setup to handle all argument types yet, or any optional arguments'
  #     end
  #   end

  #   if error
  #     return false
  #   else
  #     return result
  #   end
  # end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # args = createRunVariables(runner, workspace, user_arguments, arguments(workspace))
    # if !args then return false end

    option = runner.getStringArgumentValue("option", user_arguments)

    # reporting initial condition of model
    starting_tariffs = workspace.getObjectsByType('UtilityCost:Tariff'.to_IddObjectType)
    runner.registerInitialCondition("The model started with #{starting_tariffs.size} tariff objects.")

    # load tariff idf file based on option choice
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/SCE GS TOU #{option} Rates_test.idf")
    file = OpenStudio::IdfFile.load(path)

    if file.empty? 
      runner.registerError("Unable to find #{option} Tariff File. Contact Support.")
      return false
    else
      file = file.get
    end

    # add everything from the file
    workspace.addObjects(file.objects)

    # register what happened
    runner.registerInfo("Added #{file.objects.size} #{option} tariff and rate objects.")


    # # loop though args to make tariff for each one
    # args.each do |k, v|
    #   # load the idf file containing the electric tariff
    #   tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{v}.idf")
    #   tar_file = OpenStudio::IdfFile.load(tar_path)

    #   # in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
    #   # below is a temporary workaround for this before issuing an error.
    #   if tar_file.empty?
    #     tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{v}.idf")
    #     tar_file = OpenStudio::IdfFile.load(tar_path)
    #   end

    #   if tar_file.empty?
    #     runner.registerError("Unable to find the file #{v}.idf")
    #     return false
    #   else
    #     tar_file = tar_file.get
    #   end

    #   # add everything from the file
    #   workspace.addObjects(tar_file.objects)

    #   # let the user know what happened
    #   runner.registerInfo("added a #{k} tariff from #{v}.idf")
    # end

    # set the simulation timestep to 15min (4 per hour) to match the demand window of the tariffs
    if !workspace.getObjectsByType('Timestep'.to_IddObjectType).empty?
      initial_timestep = workspace.getObjectsByType('Timestep'.to_IddObjectType)[0].getString(0)
      if initial_timestep.to_s != '4'
        workspace.getObjectsByType('Timestep'.to_IddObjectType)[0].setString(0, '4')
        runner.registerInfo("Changing the simulation timestep to 4 timesteps per hour from #{initial_timestep} per hour to match the demand window of the tariffs")
      end
    else
      # add a timestep object to the workspace
      new_object_string = "
      Timestep,
        4;                                      !- Number of Timesteps per Hour
        "
      idfObject = OpenStudio::IdfObject.load(new_object_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_object = wsObject.get
      runner.registerInfo('No timestep object found. Added a new timestep object set to 4 timesteps per hour')
    end

    # report final condition of model
    finishing_tariffs = workspace.getObjectsByType('UtilityCost:Tariff'.to_IddObjectType)
    runner.registerFinalCondition("The model finished with #{finishing_tariffs.size} tariff objects.")

    return true
  end
end

# register the measure to be used by the application
AddSCETariffs.new.registerWithApplication
