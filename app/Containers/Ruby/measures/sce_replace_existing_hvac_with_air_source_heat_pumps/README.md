

###### (Automatically generated documentation)

# SCE Replace Existing HVAC with Air Source Heat Pumps

## Description
Replaces existing building HVAC systems with one of a selection of air-source heat pump systems. Heat pump rated heating COP will be a user input. Cooling and primary equipment efficiency will be set according to DEER standards for the selected DEER vintage. 

## Modeler Description
The measure will remove all exisiting HVAC equipment and replace them with the user-selected system type. Packaged single-zone systems will be applied to each zone; DOAS systems will create DOAS per floor, with FCUs per zone. One AHU will be created per floor with one reheat terminal per zone. Hydronic systems will receive one heating and one cooling plant loop per building. 
System capacity will be auto-sized by the simulation program. Cooling efficiency will be set per DEER vintage, heat pump efficiency will be user-enterable, with one value applied to all heat pump heating equipment added.  


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Target DEER Standard

**Name:** template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC System Type

**Name:** system_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heat Pump Cooling Rated COP
This value will be applied to all zone-level or plant-level cooling equipment
**Name:** cool_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heat Pump Heating Rated COP
This value will be applied to all zone-level or plant-level heating equipment
**Name:** heat_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




