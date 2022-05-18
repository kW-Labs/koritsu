

###### (Automatically generated documentation)

# SCE Replace Existing DHW with Heat Pump Water Heater

## Description
Removes the existing domestic hot water heating source and replaces it with a heat pump water heater

## Modeler Description
The measure replaces the DHW heating source, without impacting DHW demand or temperatures. System performance will be set by Rated COP input; system curves will be 'typical' (default) and not guaranteed to reflect a particular model. The added HPWH will be auto sized by the simulation to provide the capacity needed to meet building demand. This measure may be used to simulate exclusively heat pump heated tanks, exclusively electrically heated tanks, or a combination of both.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Set hot water tank volume [gal]
Enter 0 to use existing tank volume(s). Values less than 5 are treated as sizing multipliers.
**Name:** vol,
**Type:** Double,
**Units:** gal,
**Required:** true,
**Model Dependent:** false


### Set heat pump heating capacity. An input of zero will use the existing water heater capacity.
[kW]
**Name:** cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set heat pump rated COP (heating)

**Name:** cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Oversizing Factor
Sets a multiplier on autosized tank volume and heating capacity. Decimal values > 1.0 accepted.
**Name:** osz_factor,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set electric backup heating capacity. An input of zero will use existing heater capacity.
[kW]
**Name:** bu_cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Daily Flex Period 1:
Applies every day in the full run period.
**Name:** flex0,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Charge - Heat Pump", "Charge - Electric", "Float"]


### Use 24-Hour Format

**Name:** flex_hrs0,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Daily Flex Period 2:
Applies every day in the full run period.
**Name:** flex1,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Charge - Heat Pump", "Charge - Electric", "Float"]


### Use 24-Hour Format

**Name:** flex_hrs1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Daily Flex Period 3:
Applies every day in the full run period.
**Name:** flex2,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Charge - Heat Pump", "Charge - Electric", "Float"]


### Use 24-Hour Format

**Name:** flex_hrs2,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Daily Flex Period 4:
Applies every day in the full run period.
**Name:** flex3,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Charge - Heat Pump", "Charge - Electric", "Float"]


### Use 24-Hour Format

**Name:** flex_hrs3,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set maximum tank temperature
[F]
**Name:** max_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set minimum tank temperature during float
[F]
**Name:** min_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Set deadband temperature difference between heat pump and electric backup
[F]
**Name:** db_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






