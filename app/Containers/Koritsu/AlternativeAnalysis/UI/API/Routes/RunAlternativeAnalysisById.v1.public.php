<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            runAlternativeAnalysisById
 * @api                {get} /v1/alternative_analyses/:id/run  Runs Alternative Analysis
 * @apiDescription     Runs Alternative Analysis by its ID, then dispatch the Open Studio Baseline Analysis Job Flow.
 *                     The Job flow is as follows: (1) Run Open Studio Baseline Analysis via Ruby Script (2) Check for status updates every 20 seconds until complete
 *                     (3) Once Complete, save Open Studio Results to local Storage.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiError Conflict The user does not have permission to this analysis.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 409 Conflict
 * {
 *  "message": "The selected Analysis does not belong to the current User."
 * }
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('alternative_analyses/{id}/run', [Controller::class, 'runAlternativeAnalysisById'])
    ->name('api_run_alternative_analyses')
    ->middleware(['auth:api']);
