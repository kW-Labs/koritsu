<?php

/**
 * @apiGroup           Projects
 * @apiName            findProjectById
 * @api                {get} /v1/projects/:id Find Project
 * @apiDescription     Find a project by its ID
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Project ID

 * @apiError Conflict The user does not have permission to this project.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 409 Conflict
 * {
 *  "message": "The selected Project does not belong to the current User."
 * }
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('projects/{id}', [Controller::class, 'findProjectById'])
    ->name('api_find_projects')
    ->middleware(['auth:api']);
