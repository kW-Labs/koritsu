

###### (Automatically generated documentation)

# SCE Replace Existing HVAC with Ground Source Heat Pumps

## Description
Replaces building HVAC systems with one of a selection of Ground-source heat pump configurations, with user-input cooling and heating rated efficiencies. A ground loop will be created to reject/obtain heat for water-source heat pumps that approximates a properly sized ground heat exchanger without requiring a detailed ground loop sizing simulation.

## Modeler Description
The measure will remove all the existing building HVAC systems and replace them with the user-specified system. A ground-source heat pump will be added to each zone in the model. The option to add a dedicated outdoor air system (DOAS) will add one per floor to provide pre-conditioned ventilation air to the zones. DOAS cooling source can be either packaged DX or GSHP; DOAS heating source can be gas furnace, electric resistance, packaged DX (heat pump) or WSHP. User will be able to input efficiencies for DOAS cooilng and heating source, to be applied to all DOASs.
The GSHPs will reject heat to a common ground loop. The ground loop capacity will be approximated by a linear function of temperature difference across the loop – this measure does not specificlly size a ground loop. 
User input of GSHP cooling and heating efficiency will be applied equally to all zone-level heat pumps added. 


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

### Ground-Source Heat Pump Cooling Rated COP
This value will be applied to all zone-level GSHP equipment in cooling.
**Name:** cool_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Ground-Source Heat Pump Heating Rated COP
This value will be applied to all zone-level GSHP equipment in heating.
**Name:** heat_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




