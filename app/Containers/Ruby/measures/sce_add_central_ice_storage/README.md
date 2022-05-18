

###### (Automatically generated documentation)

# SCE Add Central Ice Storage

## Description
Adds an ice storage tank and controls to existing chilled water loop for the purpose of thermal energy storage.

## Modeler Description
The measure allows users attach ice thermal energy storage (ITS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Thermal Storage Capacity (ton-hours)
Energy capacity of Ice thermal storage in ton-hours
**Name:** stor_cap,
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






