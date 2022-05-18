<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            getAlternativeAnalysisStatus
 * @api                {get} /v1/alternative_analyses/:id/status Get Alternative Analysis Status from Open Studio Server
 * @apiDescription     Get Alternative Analysis Status from Open Studio Server for a particular Alternative Analysis ID
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('alternative_analyses/{id}/status', [Controller::class, 'getStatus'])
    ->name('api_get_alternative_analysis_status')
    ->middleware(['auth:api']);
