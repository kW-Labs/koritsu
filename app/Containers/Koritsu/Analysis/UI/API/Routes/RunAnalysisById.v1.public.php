<?php

/**
 * @apiGroup           Analyses
 * @apiName            runAnalysisById
 * @api                {get} /v1/analyses/:id/run  Runs Analysis
 * @apiDescription     Runs analysis by its ID. This is used if a project has not run any analysis or if a project needs to be re-run the analysis.
 *                     This task dispatches the Open Studio Baseline Analysis Job Flow. The Job flow is as follows: (1) Run Open Studio Baseline Analysis
 *                     via Ruby Script (2) Check for status updates every 20 seconds until complete (3) Once Complete, save Open Studio Results to local Storage.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Analysis ID
 *
 * @apiError Conflict The user does not have permission to this analysis.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 409 Conflict
 * {
 *  "message": "The selected Analysis does not belong to the current User."
 * }
 */

use App\Containers\Koritsu\Analysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('analyses/{id}/run', [Controller::class, 'runAnalysisById'])
    ->name('api_run_analyses')
    ->middleware(['auth:api']);
