<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            updateAlternativeAnalysisMeasures
 *
 * @api                {PUT} /v1/alternative_analyses/{id}/measures Update Alternative Analysis Measures
 * @apiDescription     Update Alternative Analysis Measures in json object
 *
 * @apiVersion         1.0.0
 * @apiPermission      update-analysis
 *
 * @apiParam           {json}  data Project Data in json

 * @apiSuccessExample  {json}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "data":{
 *      "object":"Project",
 *      "id":"6dpbgq5ka0axoe8r",
 *      "name":"Test #2",
 *      "data":"{"name":"Building Name"}",
 *      "user_id":"pvnxml0njyj6r3eg",
 *      "created_at":"2021-03-03T06:55:53.000000Z",
 *      "updated_at":"2021-03-03T06:55:53.000000Z",
 *      "real_id":2
 * },
 * "meta":{
 *      "include":[],
 *      "custom":[]
 *  }
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

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::put('alternative_analyses/{id}/measures', [Controller::class, 'updateAlternativeAnalysisMeasures'])
    ->name('api_update_alternative_analysis_measures')
    ->middleware(['auth:api']);
