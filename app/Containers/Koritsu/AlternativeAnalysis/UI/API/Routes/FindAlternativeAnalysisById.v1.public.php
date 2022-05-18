<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            findAlternativeAnalysisById
 * @api                {get} /v1/alternative_analyses/:id Find Alternative Analysis
 * @apiDescription     Find an Alternative Analysis by its ID
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

Route::get('alternative_analyses/{id}', [Controller::class, 'findAlternativeAnalysisById'])
    ->name('api_find_alternative_analyses')
    ->middleware(['auth:api']);
