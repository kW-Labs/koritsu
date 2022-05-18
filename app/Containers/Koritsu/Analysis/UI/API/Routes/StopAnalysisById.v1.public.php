<?php

/**
 * @apiGroup           Analyses
 * @apiName            stopAnalysisById
 * @api                {get} /v1/analyses/:id Stops Running Analysis
 * @apiDescription     Stops a running analysis by its ID. This sends a cancel command to the Open Studio Server to cancel the running job.
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

Route::get('analyses/{id}/stop', [Controller::class, 'stopAnalysisById'])
    ->name('api_stop_analyses')
    ->middleware(['auth:api']);
