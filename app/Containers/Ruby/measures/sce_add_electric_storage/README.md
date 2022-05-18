

###### (Automatically generated documentation)

# SCE Add Electric Storage

## Description
Adds electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge

## Modeler Description
Adds simple electric storage in the model and offers two methods of controlling storage charging and discharging.
    Method 1.) Facility Demand Leveling – Storage will attempt to control the facility’s power demand drawn from the utility service to a prescribed level. When facility demand is below the target level the storage acts as a load on the grid and is charged. When facility demand is above the target level the storage is discharged to the grid to maintain the demand target.
    Method 2.) Scheduled Charging/Discharging Storage – Storage is scheduled to be charged and discharged according to specific charge and discharge schedules usually associated with time-of-day utility tariffs. User input will consist of daily start hour and end hour of charging and discharging periods.
    

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Battery Storage Control Mode
'Facility Demand Leveling' will attempt to control the facility's power demand dran from the utility service to a prescribed level. Scheduled will follow a user-input charging/discharging schedule.
**Name:** stor_op,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Facility Demand Leveling", "Scheduled"]


### Utility Demand Target (kW)
If Storage Control Mode = 'Facility Demand Leveling', this sets the target facility demand for discharge control - battery will discharge to maintain this demand level.
**Name:** demand_target,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery Charge Hours
If Storage Control Mode = 'Scheduled', enter daily times for battery charging, using 24-hour format. Applies every day in the full run period.
**Name:** charge_hours,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery Storage Capacity (kWh)
Total energy storage capacity of battery. Default represents Tesla Powerwall 2.
**Name:** stor_cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery Charge/Discharge Power (kW)
Maximum rate at which electrical power can be charged/discharged from the battery. Default represents Tesla Powerwall 2.
**Name:** power,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Nominal 'round-trip' (charge and discharge) energetic efficiency.
Energetic efficiency from storing and drawing electricl energy from the battery. Values should be between 0.001 and 1.0. Model inputs for charing and discharging efficiency will be the square root of this total 'round-trip' value. Default value represents Tesla Powerwall 2.
**Name:** tot_eff,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






