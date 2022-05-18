

###### (Automatically generated documentation)

# SCE Add Photovoltaic with Electric Storage

## Description
Adds photovoltaic generation and electric storage in the model and offers two methods of controlling storage charging and discharging: Facility Demand Leveling, or Scheduled Charge and Discharge

## Modeler Description
Adds a photovoltaic array for electric generation and simple electric storage in the model. Offers two methods of controlling storage charging and discharging. The PV array will be located on the exterior of the building. A fixed cell efficiency will be assigned in the model. A fraction of the array’s surface area with active cells will also be assigned in the model to account for periods in which there is cloud cover or shading. The PVs inverter will be sized equal to the rated PV array power. The inverter will use a simple fixed efficiency.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### The total system generating capacity in kilowatts

**Name:** pv_cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### PV Module Type
PV system module type: <br>
                               'Standard': typical poly- or mono-crystalline modules with efficiencies from 14-17%.<br>
                               'Premium': monocrystalline silicon modules with anti-reflective coating and high efficiency (18-20%).<br>
                               'ThinFilm': thin film modules with low temperature coefficient and low efficiency ~11%.
**Name:** pv_mod_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Standard", "Premium", "ThinFilm"]


### PV Array Position Input Type
Enter the input type for PV panel position: <br>
                          'Ideal' will calculate the panel tilt based on project (weather file) latitude.<br>
                          'Specified' will use tilt value entered in 'Panel Tilt' argument below.
**Name:** pv_pos,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Ideal", "Specified"]


### PV Panel Tilt Angle (deg)
Angle that the panel is tilted from horizontal (0° - horizontal; 90° - vertical).<br>Note: this argument only used if 'PV Array Position Input Type' = 'Specified'.
**Name:** tilt,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


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






