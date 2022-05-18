<?php

/**
 * @apiGroup           Analyses
 * @apiName            findAnalysisById
 * @api                {get} /v1/analyses/:id Find Analysis
 * @apiDescription     Find an analysis by its ID
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

Route::get('analyses/{id}', [Controller::class, 'findAnalysisById'])
    ->name('api_find_analyses')
    ->middleware(['auth:api']);
