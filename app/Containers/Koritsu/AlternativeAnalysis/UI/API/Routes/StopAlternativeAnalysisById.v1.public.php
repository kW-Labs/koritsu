<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            stopAnalysisById
 * @api                {get} /v1/alternative_analyses/:id Stops Running Alternative Analysis
 * @apiDescription     Stops a running Alternative Analysis by its ID. This sends a cancel command to the Open Studio Server to cancel the running job.
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

Route::get('alternative_analyses/{id}/stop', [Controller::class, 'stopAlternativeAnalysisById'])
    ->name('api_stop_alternative_analyses')
    ->middleware(['auth:api']);
