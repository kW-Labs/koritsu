<?php

/**
 * @apiGroup           Projects
 * @apiName            createWithAnalysis
 *
 * @api                {POST} /v1/projects/createWithAnalysis Create a new Project And Run a Baseline Analysis
 * @apiDescription     Create a new project using the logged-in user, then dispatch the Open Studio Baseline Analysis Job Flow.
 *                     The Job flow is as follows: (1) Run Open Studio Baseline Analysis via Ruby Script
 *                     (2) Check for status updates every 20 seconds until complete
 *                     (3) Once Complete, save Open Studio Results to local Storage.
 *
 * @apiVersion         1.0.0
 * @apiPermission      create-projects
 *
 * @apiParam           {JSON}  data Project Data
 *
 * @apiExample {JSON} Creating a Project with Analysis
 * {"data":{"project_name":"My Name","location":"San Francisco Intl Ap","bldg_type_a":"Asm","template":"DEER 2017","total_bldg_floor_area":"100000","floor_height":"15","num_stories_above_grade":"2","num_stories_below_grade":"0","building_rotation":"12","ns_to_ew_ratio":"2","perim_mult":"0","wwr":"0.35","system_type":"VAV district chilled water with district hot water reheat","hvac_delivery_type":"Forced Air","htg_src":"NaturalGas","clg_src":"Electricity","swh_src":"Inferred","kitchen_makeup":"None","exterior_lighting_zone":"3 - All Other Areas","onsite_parking_fraction":"0.25","modify_wkdy_op_hrs":"true","wkdy_op_hrs_start_time":"6","wkdy_op_hrs_duration":"10","modify_wknd_op_hrs":"true","wknd_op_hrs_start_time":"10","wknd_op_hrs_duration":"4","unmet_hours_tolerance":"2","sce_rate_type":"Option D","state":"CA"}}
 *
 * @apiSuccessExample  {json}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "data":{
 *  "object":"projects",
 *  "id":"O9apoVGyLz5qNX4K",
 *  "data":"{\"project_name\":\"My Name\",\"location\":\"San Francisco Intl Ap\",\"bldg_type_a\":\"Asm\",\"template\":\"DEER 2017\",\"total_bldg_floor_area\":\"100000\",\"floor_height\":\"15\",\"num_stories_above_grade\":\"2\",\"num_stories_below_grade\":\"0\",\"building_rotation\":\"12\",\"ns_to_ew_ratio\":\"2\",\"perim_mult\":\"0\",\"wwr\":\"0.35\",\"system_type\":\"VAV district chilled water with district hot water reheat\",\"hvac_delivery_type\":\"Forced Air\",\"htg_src\":\"NaturalGas\",\"clg_src\":\"Electricity\",\"swh_src\":\"Inferred\",\"kitchen_makeup\":\"None\",\"exterior_lighting_zone\":\"3 - All Other Areas\",\"onsite_parking_fraction\":\"0.25\",\"modify_wkdy_op_hrs\":\"true\",\"wkdy_op_hrs_start_time\":\"6\",\"wkdy_op_hrs_duration\":\"10\",\"modify_wknd_op_hrs\":\"true\",\"wknd_op_hrs_start_time\":\"10\",\"wknd_op_hrs_duration\":\"4\",\"unmet_hours_tolerance\":\"2\",\"sce_rate_type\":\"Option D\",\"state\":\"CA\"}",
 *  "analysis_id":null,
 *  "user_id":"39n0Z12OZGKERJgW",
 *  "created_at":"2022-03-07T18:14:44.000000Z",
 *  "updated_at":"2022-03-07T18:14:44.000000Z"
 * },
 * "meta":{
 *  "include":[
 *  "analysis"
 * ],
 * "custom":[]
 * }
 * }
 *
 * @apiError Unauthorized The user does not have permission to create a project.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 403 Forbidden
 * {
 *  "message": "This action is unauthorized."
 * }
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::post('projects/createWithAnalysis', [Controller::class, 'createProjectAndAnalysis'])
    ->name('api_create_project_and_run_baseline_analysis')
    ->middleware(['auth:api']);
