<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            deleteAlternativeAnalysisMeasure
 * @api                {delete} /v1/alternative_analyses/:id/measures/:name Delete Alternative Analysis Measure
 * @apiDescription     Delete Alternative Analysis Measure
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiParam           {String} name Measure name
 * @apiSuccessExample  {json}       Success-Response:
 * HTTP/1.1 204 No Content
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::delete('alternative_analyses/{id}/measures/{name}', [Controller::class, 'deleteAlternativeAnalysisMeasure'])
    ->name('api_delete_alternative_analysis_measure')
    ->middleware(['auth:api']);
