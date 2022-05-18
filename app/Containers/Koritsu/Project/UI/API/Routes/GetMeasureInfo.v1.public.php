<?php

/**
 * @apiGroup           Projects
 * @apiName            getMeasureInfo
 *
 * @api                {PUT} /v1/projects/:id/measure_info/:measure_name Gets the measure info
 * @apiDescription     Gets the alternative measure info details for a giving project id and measure name. This will run a Ruby script to get the measure details
 *                     based on the Open Studio Results.
 *
 * @apiVersion         1.0.0
 * @apiPermission      update-projects
 *
 * @apiParam           {Number}  id Project ID
 * @apiParam           {String}  measure_name Open Studio Measure Name
 *
 * @apiExample {get} Getting Measure info for a Project
 * /projects/aYOxlpzRMwrX3gD7/measure_info/IncreaseInsulationRValueForRoofs
 *
 * @apiSuccessExample  {JSON}  Success-Response:
 * HTTP/1.1 200 OK
* {
* "measure_dir": "/home/vagrant/code/Koritsu_analysis/.bundle/install/ruby/2.5.0/gems/openstudio-ee-0.3.2/lib/measures/ReduceLightingLoadsByPercentage",
* "name": "reduce_lighting_loads_by_percentage",
* "directory": "/home/vagrant/code/Koritsu_analysis/.bundle/install/ruby/2.5.0/gems/openstudio-ee-0.3.2/lib/measures/ReduceLightingLoadsByPercentage",
* "uid": "791f3404-a28b-4a80-ba3f-e15b339e39ea",
* "uuid": "{791f3404-a28b-4a80-ba3f-e15b339e39ea}",
* "version_id": "59b68a01-ac95-49b1-9dd2-610f507e3271",
* "version_uuid": "{59b68a01-ac95-49b1-9dd2-610f507e3271}",
* "version_modified": "20210405T230649Z",
* "xml_checksum": "293730A7",
* "display_name": "Reduce Lighting Loads by Percentage",
* "class_name": "ReduceLightingLoadsByPercentage",
* "description": "The lighting system in this building uses more power per area than is required with the latest lighting technologies. Replace the lighting system with a newer, more efficient lighting technology. Newer technologies provide the same amount of light but use less energy in the process.",
* "modeler_description": "This measure supports models which have a mixture of lighting assigned to spaces and space types. The lighting may be specified as individual luminaires, lighting equipment level, lighting power per area, or lighting power per person. Loop through all lights and luminaires in the specified space type or the entire building. Clone the definition if it is shared by other lights, rename and adjust the power based on the specified percentage. Link the new definition to the existing lights or luminaire instance. Adjust the power for lighting equipment assigned to a particular space but only if that space is part of the selected space type by looping through the objects first in space types and then in spaces, but again only for spaces that are in the specified space type (unless the entire building has been chosen). Material and installation cost increases will be applied to all costs related to both the definition and instance of the lighting object. If this measure includes baseline costs, then the material and installation costs of the lighting objects in the baseline model will be summed together and added as a capital cost on the building object.",
* "tags": [
* "Electric Lighting.Lighting Equipment"
* ],
* "outputs": [],
* "attributes": [
* {
* "name": "Measure Type",
* "display_name": "Measure Type",
* "value": "ModelMeasure"
* },
* {
* "name": "Measure Function",
* "display_name": "Measure Function",
* "value": "Measure"
* },
* {
* "name": "Requires EnergyPlus Results",
* "display_name": "Requires EnergyPlus Results",
* "value": false
* },
* {
* "name": "Uses SketchUp API",
* "display_name": "Uses SketchUp API",
* "value": false
* }
* ],
* "arguments": [
* {
* "name": "space_type",
* "display_name": "Apply the Measure to a Specific Space Type or to the Entire Model",
* "description": "",
* "type": "Choice",
* "required": true,
* "model_dependent": false,
* "default_value": "{577b5356-35f1-4ca1-b74e-c02578cbbc39}",
* "choice_values": [
* "{577b5356-35f1-4ca1-b74e-c02578cbbc39}"
* ],
* "choice_display_names": [
* "*Entire Building*"
* ],
* },
* {
* "name": "lighting_power_reduction_percent",
* "display_name": "Lighting Power Reduction",
* "description": "",
* "type": "Double",
* "required": true,
* "model_dependent": false,
* "units": "%",
* "default_value": 30
* },
* {
* "name": "material_and_installation_cost",
* "display_name": "Increase in Material and Installation Cost for Lighting per Floor Area",
* "description": "",
* "type": "Double",
* "required": true,
* "model_dependent": false,
* "units": "%",
* "default_value": 0
* },
* {
* "name": "demolition_cost",
* "display_name": "Increase in Demolition Costs for Lighting per Floor Area",
* "description": "",
* "type": "Double",
* "required": true,
* "model_dependent": false,
* "units": "%",
* "default_value": 0
* },
* {
* "name": "years_until_costs_start",
* "display_name": "Years Until Costs Start",
* "description": "",
* "type": "Integer",
* "required": true,
* "model_dependent": false,
* "units": "whole years",
* "default_value": 0
* },
* {
* "name": "demo_cost_initial_const",
* "display_name": "Demolition Costs Occur During Initial Construction",
* "description": "",
* "type": "Boolean",
* "required": true,
* "model_dependent": false,
* "default_value": false
* },
* {
* "name": "expected_life",
* "display_name": "Expected Life",
* "description": "",
* "type": "Integer",
* "required": true,
* "model_dependent": false,
* "units": "whole years",
* "default_value": 15
* },
* {
* "name": "om_cost",
* "display_name": "Increase O & M Costs for Lighting per Floor Area",
* "description": "",
* "type": "Double",
* "required": true,
 * "model_dependent": false,
 * "units": "%",
 * "default_value": 0
 * },
 * {
 * "name": "om_frequency",
 * "display_name": "O & M Frequency",
 * "description": "",
 * "type": "Integer",
 * "required": true,
 * "model_dependent": false,
 * "units": "whole years",
 * "default_value": 1
 * }
 * ],
 * }
 * }
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('projects/{id}/measure_info/{measure_name}', [Controller::class, 'getMeasureInfo'])
    ->name('api_get_measure_info')
    ->middleware(['auth:api']);
