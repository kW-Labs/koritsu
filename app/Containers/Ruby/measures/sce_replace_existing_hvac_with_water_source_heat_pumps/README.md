

###### (Automatically generated documentation)

# SCE Replace Existing HVAC with Water-Source Heat Pumps

## Description
Replaces building HVAC system with one of a selection of WSHP system configurations. System cooling and heating rated efficiency will be user inputs. Primary equipment (chiller/boiler, cooling tower, etc) efficiency will meet DEER parameters according to the user-entered DEER vintage

## Modeler Description
The measure will remove all the existing building HVAC systems and replace them with the user-specifed system. A water-source heat pump will be added for each zone in the model. The option to add a dedicated outdoor air system (DOAS) will add one per floor to provide pre-conditioned ventilation air to the zones. DOAS cooling source can be either packaged DX or WSHP; DOAS heating source can be gas furnace, electric resistance, packaged DX (heat pump) or WSHP. User will be able to input efficiencies for DOAS cooling and heating source, to be applied to all DOASs.
The WSHPs will reject heat to a common condensing water loop. Options for loop heat rejection equipment include a variable-speed cooling tower or fluid cooler, options for heat addition equipment include gas boiler, electric resistance boiler or air-to-water heat pump. User will be able to specify heating source efficiency (percent for gas boiler, COP for Air to Water Heat Pump.
User input of WSHP cooling and heating efficiency will be applied equally to all zone-level heat pumps added.


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

### Add Dedicated Outdoor Air System (DOAS)
If selected, a Dedicated Outdoor Air System will be added per floor to precondition outside air delivered to the zones.
**Name:** doas,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Cooling Source for DOAS
Sets the cooling source for the Dedicated Outside Air System.
**Name:** doas_cool,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### DOAS Cooling Source Rated COP
This value will be applied to DOAS cooling equipment
**Name:** doas_cool_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heating Source for DOAS
Sets the heating source for the Dedicated Outside Air System.
**Name:** doas_heat,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### DOAS Heating Source Rated Efficiency
This value will be applied to DOAS heating equipment.
For gas furnace, enter a value less than 1 as furnace AFUE.
For Electric resistance, enter 1.0.
For WSHP/Air-source heat pump this is rated COP (>1).
**Name:** doas_heat_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### WSHP Loop Heat Rejection Equipment
Type of equipment used to reject heat from the WSHP water loop
**Name:** loop_cool,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### WSHP Loop Heating Equipment
Type of equipment used to add heat to the WSHP water loop
**Name:** loop_heat,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### WSHP Heating Source Rated Efficiency
This value will be applied to WSHP loop heating equipment.
For gas boiler, enter a value less than 1 as boiler thermal efficiency.
For Electric boiler, enter 1.0.
For Central Air-water heat pump this is rated COP (>1).
**Name:** loop_heat_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Water-Source Heat Pump Cooling Rated COP
This value will be applied to all zone-level WSHP equipment in cooling.
**Name:** cool_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heat Pump Heating Rated COP
This value will be applied to all zone-level WSHP equipment in heating.
**Name:** heat_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




