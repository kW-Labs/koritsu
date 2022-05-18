

###### (Automatically generated documentation)

# SCE Add Chilled Water Storage

## Description
This measure adds a chilled water thermal energy storage tank to the model for the purpose load shifting.

## Modeler Description
The measure allows users attach chilled water thermal energy storage (CWTS) to an existing chilled water loop for the purpose of exploring load flexibility potential for a given building. The baseline chilled water loop will be split into a 'primary' and 'secondary' loop, with the primary loop contiaing the existing chiller (hardsized to maintain baseline sizing) on the supply side and a ThermalStorage:ChilledWater:Stratified on the demand side. The secondary loop contains the chilled water tank on the supply side and existing chilled water coils on the demand side. The chilled water tank is modeled as a vertical cylinder with minimal surface area for a given tank volume. Tank is assumed to be exposed to ambient conditions, with a surface U-value of 0.5 W/m^2*K

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Chilled Water Storage Tank Volume (ft^3)
Storage volume of chilled water tank in cubic feet.
**Name:** tank_vol,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Chilled Water Storage Cooling Capacity (tons)
Cooling capacity of chilled water thermal storage tank in tons
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






