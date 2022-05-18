<?php

/**
 * @apiGroup           Analyses
 * @apiName            getDownload
 * @api                {get} /v1/analysis/:id/download/:file Downloads Open Studio File
 * @apiDescription     Allows user to download copy of the project in Zip or HTML format. The files originally came from Open Studio Server after running analysis and status is completed.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Analysis ID
 * @apiParam           {String} file Download File Name is either "openstudio_report" for zip or "anything" for html file
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\Analysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('analyses/{id}/download/{file}', [Controller::class, 'getDownload'])
    ->name('api_get_download')
    ->middleware(['auth:api']);
