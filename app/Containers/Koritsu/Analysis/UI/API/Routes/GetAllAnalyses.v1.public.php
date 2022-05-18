<?php

/**
 * @apiGroup           Analyses
 * @apiName            getAllAnalyses
 * @api                {get} /v1/projects/:id/analyses Get All Analyses for a Project
 * @apiDescription     Get All Analyses for the logged-in user for a particular Project
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

Route::get('projects/{id}/analyses', [Controller::class, 'getAllAnalyses'])
    ->name('api_find_all_analyses')
    ->middleware(['auth:api']);
