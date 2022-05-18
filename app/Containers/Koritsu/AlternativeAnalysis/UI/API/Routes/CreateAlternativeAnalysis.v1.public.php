<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            createAlternativeAnalysis
 *
 * @api                {POST} /v1/analyses/:id/alternatives/create Creates Alternative Analysis
 * @apiDescription     Create a new Alternative Analysis to a Project Analysis baseline using the logged in user, then dispatch the Open Studio Baseline Analysis Job Flow.
 *                     The Job flow is as follows: (1) Run Open Studio Baseline Analysis via Ruby Script (2) Check for status updates every 20 seconds until complete
 *                     (3) Once Complete, save Open Studio Results to local Storage.
 *
 * @apiVersion         1.0.0
 * @apiPermission      create-analyses
 *
 * @apiParam           {Number} id  Analysis ID
 * @apiParam           {String}  name Alternative Name
 *
 * @apiSuccessExample  {json}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "data":{
 *      "object":"AlternativeAnalysis",
 *      "id":"63opkryv7yvjeng4",
 *      "name":"Run Base",
 *      "data": "{"weather_file_name":"USA_CO_Boulder-Broomfield-Jefferson.County.AP.724699_TMY3.epw","alternative_name":"Base","project_id":1,"project_name":"Test #2","measures":[{"name":"ChangeBuildingLocation","args":{"weather_file_name":"USA_CO_Boulder-Broomfield-Jefferson.County.AP.724699_TMY3.epw","climate_zone":"ASHRAE 169-2013-5B"}},{"name":"create_bar_from_building_type_ratios","args":{"climate_zone":"ASHRAE 169-2013-5B"}},{"name":"create_typical_building_from_model","args":[]}]}",
 *      "host":"52.41.8.94",
 *      "results": "{"success":true,"error_msg":"","created_project":true,"created_seed":true,"copied_weather_file":true,"created_osw":true,"created_osa":true,"ran_analysis":true,"analysis_id":" ffb3cab6-8a7c-4d01-9da3-ba1d86b669e4","debug":false,"log":[]}",
 *      "type_id":1,
 *      "analysis_id":"ffb3cab6-8a7c-4d01-9da3-ba1d86b669e4",
 *      "status": "{"analysis":{"status":"started"}}",
 *      "project_id":"azkvml597yxe8b9j",
 *      "user_id":"azkvml597yxe8b9j",
 *      "created_at":"2021-03-16T00:11:28.000000Z",
 *      "updated_at":"2021-03-16T00:11:28.000000Z",
 *      "real_id":22
 * },
 * "meta":{
 *      "include":[],
 *      "custom":[]
 * }
 * }
 *
 * @apiError Unauthorized The user does not have permission to create a analysis.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 403 Forbidden
 * {
 *  "message": "This action is unauthorized."
 * }
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::post('analyses/{id}/alternatives/create', [Controller::class, 'createAlternativeAnalysis'])
    ->name('api_create_alternative_analysis')
    ->middleware(['auth:api']);
