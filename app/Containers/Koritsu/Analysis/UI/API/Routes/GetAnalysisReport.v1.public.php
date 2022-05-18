<?php

/**
 * @apiGroup           Analyses
 * @apiName            getAnalysisReport
 * @api                {get} /v1/analysis/:id/report Get Analysis Report
 * @apiDescription     Return baseline run + alternative run summary json files that were run successfully. These files were copied from the Open Studio Server.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Analysis ID
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\Analysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('analyses/{id}/report', [Controller::class, 'getReport'])
    ->name('api_get_analysis_report')
    ->middleware(['auth:api']);
