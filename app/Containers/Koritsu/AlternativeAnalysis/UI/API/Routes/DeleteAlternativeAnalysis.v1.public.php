<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            deleteAlternativeAnalysis
 * @api                {delete} /v1/alternative_analyses/:id Delete Alternative Analysis
 * @apiDescription     Delete Alternative Analysis
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiSuccessExample  {json}       Success-Response:
 * HTTP/1.1 204 No Content
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::delete('alternative_analyses/{id}', [Controller::class, 'deleteAlternativeAnalysis'])
    ->name('api_delete_alternative_analysis')
    ->middleware(['auth:api']);
