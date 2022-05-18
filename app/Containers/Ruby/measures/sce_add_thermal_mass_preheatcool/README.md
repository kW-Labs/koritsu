

###### (Automatically generated documentation)

# SCE Add Thermal Mass Preheat Cool

## Description
This measure adjusts building thermal mass and cooling and heating schedules by a user specified number of degrees and time period.

## Modeler Description
HVAC operation schedule will also be changed if the start time of the pre-cooling/heating is earlier than the default start value. An optional integer input is applied to each zones’ thermal capacitance, effectively modifying the mass of material in the building’s conditioned air volume. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Precool Temperature Adjustment
Number of degrees Farenheight to offset the existing cooling setback temperature for pre-cooling.
**Name:** cool_temp_shift,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Preheat Temperature Adjustment
Number of degrees Farenheight to ofset the existing heating setback temperature for pre-heating.
**Name:** heat_temp_shift,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC Operation Start Time Shift
Enter number of hours to advance the HVAC system start time via thermostat schedule adjustment.
**Name:** start_hour_shift,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Capacitance Multiplier
This value adjusts the effective thermal storage capacity of the zones in the model, approximating and increase/decrease in thermal mass. Values above 1.0 will increase capacitance; values from 0-1 will decrease it.
**Name:** tcap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






