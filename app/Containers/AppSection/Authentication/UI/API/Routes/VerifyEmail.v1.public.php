<?php

/**
 * @apiGroup           Authentication
 * @apiName            VerifyEmail
 *
 * @api                {GET} /v1/email/verify/:id/:hash Verify Email
 * @apiDescription     Verify user email
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated
 *
 * @apiSuccessExample  {json} Success-Response:
 * HTTP/1.1 200 OK
 * {}
 */

use App\Containers\AppSection\Authentication\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('/email/verify/{id}/{hash}', [Controller::class, 'verifyEmail'])
    ->name('verification.verify');
