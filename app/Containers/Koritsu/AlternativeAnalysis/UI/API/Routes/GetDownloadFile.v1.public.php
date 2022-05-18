<?php

/**
 * @apiGroup           Alternative Analyses
 * @apiName            getDownload
 * @api                {get} /v1/alternative_analyses/:id/download/:file Get Analysis Status from Open Studio Server
 * @apiDescription     Allows user to download copy of the project in Zip or HTML format. The files originally came from Open Studio Server after running analysis and status is completed.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Alternative Analysis ID
 * @apiParam           {String} file Download File Name is either "openstudio_report" for zip or "anything" for html file
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('alternative_analyses/{id}/download/{file}', [Controller::class, 'getDownload'])
    ->name('api_get_alternative_analyses_download')
    ->middleware(['auth:api']);
