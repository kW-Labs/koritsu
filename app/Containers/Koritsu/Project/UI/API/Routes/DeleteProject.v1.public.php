<?php

/**
 * @apiGroup           Projects
 * @apiName            deleteProject
 * @api                {delete} /v1/projects/:id Delete Project
 * @apiDescription     Delete a project from the database and all the project files using the project id
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Project ID
 *
 * @apiExample {delete} Deleting a Project
 * /v1/projects/39n0Z12OZGKERJgW
 *
 * @apiSuccessExample  {json}       Success-Response:
 * HTTP/1.1 204 No Content
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::delete('projects/{id}', [Controller::class, 'deleteProject'])
    ->name('api_delete_project')
    ->middleware(['auth:api']);
