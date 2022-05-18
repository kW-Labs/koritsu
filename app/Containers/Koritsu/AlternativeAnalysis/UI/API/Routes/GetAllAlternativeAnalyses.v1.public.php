<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            getAllAlternativeAnalyses
 * @api                {get} /v1/analyses/:analysis_id/alternative_analyses Get All Alternative Analyses for an Analysis
 * @apiDescription     Get All Alternative Analyses for the logged-in user for a particular Project
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} analysis_id Analysis ID
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('analyses/{analysis_id}/alternative_analyses', [Controller::class, 'getAllAlternativeAnalyses'])
    ->name('api_find_all_alternative_analyses')
    ->middleware(['auth:api']);
