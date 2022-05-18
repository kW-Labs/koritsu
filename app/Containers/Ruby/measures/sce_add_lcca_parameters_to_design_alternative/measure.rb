# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SCEAddLCCAParameterstoDesignAlternative < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SCE Add LCCA Parameters to Design Alternative'
  end

  # human readable description
  def description
    return 'The measure adds user-input life-cycle cost parameters for the entire design alternative.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The intent of the measure is to provide a simplified LCCA calculation approach for the entire building upgrade. Life-Cycle costs will be computed following the methodology in NIST Handbook 135, using the latest published use price escalation factors.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Alternative name
    lcc_name = OpenStudio::Measure::OSArgument.makeStringArgument('lcc_name', true)
    lcc_name.setDisplayName('Alternative Name')
    lcc_name.setDefaultValue('Base')
    args << lcc_name

    # remove costs
    remove_costs = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_costs', true)
    remove_costs.setDisplayName("Remove Existing Costs")
    remove_costs.setDescription("Removes Existing costs from the model. Use if O&M costs for Alternative include those for base building.")
    remove_costs.setDefaultValue(true)
    args << remove_costs

    # length of study period
    study_period = OpenStudio::Measure::OSArgument.makeIntegerArgument('study_period', true)
    study_period.setDisplayName('Set the Length of the Study Period (years).')
    study_period.setDescription("Study period should be 25 years or fewer following FEMP LCCA guidelines.")
    study_period.setDefaultValue(25)
    args << study_period

    # total demolition cost
    demolition_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('demolition_cost', true)
    demolition_cost.setDisplayName('Total Demolition Costs')
    demolition_cost.setUnits('$')
    demolition_cost.setDefaultValue(0.0)
    args << demolition_cost

    # total construction cost
    material_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost', true)
    material_cost.setDisplayName('Total Material and Installation Costs')
    material_cost.setUnits('$')
    material_cost.setDefaultValue(0.0)
    args << material_cost

    # recurring annual O+M costs
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('Total Recurring Annual O & M Costs')
    om_cost.setUnits('$')
    om_cost.setDefaultValue(0.0)
    args << om_cost

    # make an argument for o&m frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency')
    om_frequency.setUnits('whole years')
    om_frequency.setDefaultValue(1)
    args << om_frequency

    # total upgrade replacement cost
    replacement_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('replacement_cost',true)
    replacement_cost.setDisplayName("Total Replacement Cost")
    replacement_cost.setDescription("Enter Cost to replace equipment (if occurring within study period)")
    replacement_cost.setDefaultValue(0.0)
    args << replacement_cost

    # epected life
    expected_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('expected_life', true)
    expected_life.setDisplayName("Expected Life of Upgrade")
    expected_life.setUnits('whole years')
    expected_life.setDefaultValue(20)
    args << expected_life

    remaining_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('remaining_life', true)
    remaining_life.setDisplayName("Remaining Life of Replaced Equipment")
    remaining_life.setUnits('whole years')
    remaining_life.setDefaultValue(0)
    args << remaining_life

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    lcc_name = runner.getStringArgumentValue('lcc_name', user_arguments)
    remove_costs = runner.getBoolArgumentValue('remove_costs', user_arguments)
    study_period = runner.getIntegerArgumentValue('study_period', user_arguments)
    demolition_cost = runner.getDoubleArgumentValue('demolition_cost', user_arguments)
    material_cost = runner.getDoubleArgumentValue('material_cost', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)
    replacement_cost = runner.getDoubleArgumentValue('replacement_cost', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    remaining_life = runner.getIntegerArgumentValue('remaining_life', user_arguments)

    if study_period < 1
      runner.registerError('Length of the Study Period needs to be an integer greater than 0.')
      return false
    end

    costs_requested = false
    costs_removed = false

    if material_cost + om_cost + replacement_cost == 0
      runner.registerInfo("No costs wer requested for the buliding")
    else
      costs_requested = true
    end

    if om_frequency < 1
      runner.registerError('Choose an integer greater than 0 for O & M Frequency')
      return false
    end

    # set lifcyclecost parameters
    # get lifecycle object
    lifeCycleCostParameters = model.getLifeCycleCostParameters
    lifeCycleCostParameters.setAnalysisType('FEMP')
    lifeCycleCostParameters.setLengthOfStudyPeriodInYears(study_period)
    # lifeCycleCostParameters.setBaseDateYear(Time.now.year)
    # lifeCycleCostParameters.setServiceDateYear(Time.now.year)
    # NOTE: Setting base and service date year to 2011 to align with UsePriceEscalation data used by OpenStudio 3.3.0
    lifeCycleCostParameters.setBaseDateYear(2011)
    lifeCycleCostParameters.setServiceDateYear(2011)
    
    building = model.getBuilding

    # report initial condition
    runner.registerInitialCondition("The building has #{building.lifeCycleCosts.size} lifecycle cost object.")

    if !building.lifeCycleCosts.empty? && (remove_costs == true)
      runner.registerInfo("Removing existing lifecycle cost objects associated with the building")
      removed_costs = building.removeLifeCycleCosts
      costs_removed = !removed_costs.empty?
    end

    # show as not applicable if no cost requested and if no costs removed
    if (costs_requested == false) && (costs_removed == false)
      runner.registerAsNotApplicable('No new lifecycle costs objects were requested, and no costs were deleted.')
    end

    if costs_requested

      # add new cost items
      lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demolition_#{lcc_name}", building, demolition_cost, "CostPerEach", "Salvage", expected_life, 0)
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Material_#{lcc_name}", building, material_cost, "CostPerEach", "Construction", expected_life, 0)
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM_#{lcc_name}", building, om_cost, "CostPerEach", 'Maintenance', om_frequency, 0)
      if remaining_life == 0
        lcc_replace = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Replacement_#{lcc_name}", building, replacement_cost, 'CostPerEach', 'Replacement', expected_life, expected_life)
      else 
        lcc_replace = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Replacement_#{lcc_name}", building, replacement_cost, 'CostPerEach', 'Replacement', expected_life, remaining_life)
      end
    end

    bldg_lccs = building.lifeCycleCosts
    construction_costs = 0
    recurring_costs = 0
    bldg_lccs.each do |lcc|
      if lcc.category == "Construction"
        construction_costs += lcc.totalCost
      else
        recurring_costs += lcc.totalCost
      end
    end


    if !building.lifeCycleCosts.empty?
      runner.registerFinalCondition("Total lifecycle costs added to the building total $#{construction_costs} of Construction cost and $#{recurring_costs} of Recurring Costs")
    else
      runner.registerFinalCondition("No lifecycle costs associated with the building")
    end
    

    return true
  end
end

# register the measure to be used by the application
SCEAddLCCAParameterstoDesignAlternative.new.registerWithApplication
