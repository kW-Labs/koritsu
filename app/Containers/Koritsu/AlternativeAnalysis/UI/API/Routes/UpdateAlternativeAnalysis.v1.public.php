<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            updateAlternativeAnalysis
 *
 * @api                {PUT} /v1/alternative_analyses/:id Update Alternative Analysis
 * @apiDescription     Update Alternative Analysis Name
 *
 * @apiVersion         1.0.0
 * @apiPermission      update-analysis
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiParam           {String}  name Name of the alternative

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

Route::put('alternative_analyses/{id}', [Controller::class, 'updateAlternativeAnalysis'])
    ->name('api_update_alternative_analysis')
    ->middleware(['auth:api']);
