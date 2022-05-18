<?php

/**
 * @apiGroup           Projects
 * @apiName            updateProject
 *
 * @api                {PUT} /v1/projects/:id Update Project
 * @apiDescription     Update a Project. This forces Analysis and Alternative(s) to need to be re-run.
 *
 * @apiVersion         1.0.0
 * @apiPermission      update-projects
 *
 * @apiParam           {Number}  id Project ID
 * @apiParam           {JSON}  data Project Data

 * @apiSuccessExample  {JSON}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "data":{
 *      "object":"Project",
 *      "id":"6dpbgq5ka0axoe8r",
 *      "name":"Test #2",
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

Route::put('projects/{id}', [Controller::class, 'updateProject'])
    ->name('api_update_project')
    ->middleware(['auth:api']);
