

###### (Automatically generated documentation)

# add SCE tariffs

## Description
This measure will add pre defined tariffs from IDF files in the resrouce directory for this measure. Adapted from NREL \"Tariff Selection - Generic\" measure.

## Modeler Description
The measure works by cloning objects in from an external file into the current IDF file. Change functionality by changing the resource files. This measure may also adjust the simulation timestep.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Select SCE TOU Tariff Option to Apply
The correct TOU rated will be applied based on building's peak demand
**Name:** option,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Option D", "Option E"]






