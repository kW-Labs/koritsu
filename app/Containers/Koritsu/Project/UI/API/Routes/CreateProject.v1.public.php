<?php

/**
 * @apiGroup           Projects
 * @apiName            createProject
 *
 * @api                {POST} /v1/projects/create Creates a new Project
 * @apiDescription     Create a new project using the logged-in user.
 *
 * @apiVersion         1.0.0
 * @apiPermission      create-projects
 *
 * @apiParam           {JSON}  data Project Data
 *
 * @apiExample {JSON} Creating a Project
 * {"data":{"name":"Building Name"}}
 *
 * @apiSuccessExample  {json}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "data":{
 *      "object":"Project",
 *      "id":"6dpbgq5ka0axoe8r",
 *      "data":"{"name":"Building Name"}",
 *      "user_id":"pvnxml0njyj6r3eg",
 *      "created_at":"2021-03-03T06:55:53.000000Z",
 *      "updated_at":"2021-03-03T06:55:53.000000Z",
 *      "real_id":2
 * },
 * "meta":{
 *      "include":[],
 *      "custom":[]
 *  }
 * }
 *
 * @apiError Unauthorized The user does not have permission to create a project.
 *
 * @apiErrorExample Error-Response:
 * HTTP/1.1 403 Forbidden
 * {
 *  "message": "This action is unauthorized."
 * }
 */

use App\Containers\Koritsu\Project\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::post('projects/create', [Controller::class, 'createProject'])
    ->name('api_create_project')
    ->middleware(['auth:api']);
