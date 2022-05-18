

###### (Automatically generated documentation)

# SCE Add LCCA Parameters to Design Alternative

## Description
The measure adds user-input life-cycle cost parameters for the entire design alternative.

## Modeler Description
The intent of the measure is to provide a simplified LCCA calculation approach for the entire building upgrade. Life-Cycle costs will be computed following the methodology in NIST Handbook 135, using the latest published use price escalation factors.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Alternative Name

**Name:** lcc_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Remove Existing Costs
Removes Existing costs from the model. Use if O&M costs for Alternative include those for base building.
**Name:** remove_costs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set the Length of the Study Period (years).
Study period should be 25 years or fewer following FEMP LCCA guidelines.
**Name:** study_period,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Total Demolition Costs

**Name:** demolition_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false


### Total Material and Installation Costs

**Name:** material_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false


### Total Recurring Annual O & M Costs

**Name:** om_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false


### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false


### Total Replacement Cost
Enter Cost to replace equipment (if occurring within study period)
**Name:** replacement_cost,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Expected Life of Upgrade

**Name:** expected_life,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false


### Remaining Life of Replaced Equipment

**Name:** remaining_life,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false






