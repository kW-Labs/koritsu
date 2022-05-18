

###### (Automatically generated documentation)

# SCE Demand Response

## Description
This measure adds control logic to the model to reduce the peak electrical power draw (demand) from the utility. Demand is managed in this model by turning down the lights and equipment and increasing the cooling setpoints throughout the facility.

## Modeler Description
The measure will create demand limiting objects that attempt to control electric equipment to the user-input target demand limit. The demand limiting control will attempt to limit facility demand to the target during the SCE TOU peak demand period defined in the SCE tariffs. Demand will be limited in priority order of exterior lights, interior lights, interior electric equipment, and HVAC thermostats. User will input the maximum limit fractions for each of the electric loads, and reset temperatures for the thermostats, which will be applied to all such loads and zones in the model.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Target Demand Limit
Demand response controls will adjust building loads to attempt to maintain this demand level (kW).
**Name:** demand_target,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Exterior Lighting Maximum Limit Fraction
Fraction of building's exterior lighting power to be limited in a Demand Response event (value from 0 - 1).
**Name:** ext_lt_lim_frac,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Interior Lighting Maximum Limit Fraction
Fraction of building's interior lighting power to be limited in a Demand Response event (value from 0 - 1).
**Name:** int_lt_lim_frac,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Electric Equipment Maximum Limit Fraction
Fraction of building's electric equipment (plug and process load) power to be limited in a Demand Response event (value from 0 - 1).
**Name:** equip_lim_frac,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum Temperature to Reset Thermostat Heating Setpoint
During a Demand Response event, controls will attempt to meet demand limit by resetting thermostat setpoint temperature. This is the minimum temperature the heating setpoint will be allowed to be reset (F). An input of 0 will disallow setpoint adjustment for DR.
**Name:** max_heat_reset,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum Temperature to Reset Thermostat Cooling Setpoint
During a Demand Response event, controls will attempt to meet demand limit by resetting thermostat setpoint temperature. This is the maximum temperature the cooling setpoint will be allowed to be reset (F). An input of 0 will disallow setpoint adjustment for DR.
**Name:** max_cool_reset,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






