<?php

/**
 * @apiGroup           Projects
 * @apiName            getAllProjects
 * @api                {get} /v1/projects Get All Projects
 * @apiDescription     Get All Projects for the logged-in user.
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('projects', [Controller::class, 'getAllProjects'])
    ->name('api_find_all_projects')
    ->middleware(['auth:api']);
