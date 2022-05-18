<?php

use App\Containers\Koritsu\WebApp\UI\WEB\Controllers\Controller;
use Illuminate\Support\Facades\Route;

//  Routes Matching NodeJS Routes
Route::get('/', [Controller::class, 'index'])
    ->name('web_landing_page');

Route::get('/login', [Controller::class, 'index'])
    ->name('web_landing_page_login');

Route::get('/forgotPassword', [Controller::class, 'index'])
    ->name('web_landing_page_forgot_password');

Route::get('/resetPassword', [Controller::class, 'index'])
    ->name('web_landing_page_reset_password');

Route::get('/changePassword', [Controller::class, 'index'])
    ->name('web_landing_page_change_password');

Route::get('/verifiedEmail', [Controller::class, 'index'])
    ->name('web_landing_page_verified_email');

Route::get('/register', [Controller::class, 'index'])
    ->name('web_landing_page_register');

Route::get('/projects', [Controller::class, 'index'])
    ->name('web_landing_page_projects');

// Does not exist on UI, but good to catch
Route::get('/projects/create', [Controller::class, 'index'])
    ->name('web_landing_page_projects_create');

Route::get('/projects/create/{type}', [Controller::class, 'index'])
    ->name('web_landing_page_projects_create_type_model');

Route::get('/projects/create/{type}/{weather}', [Controller::class, 'index'])
    ->name('web_landing_page_projects_create_type_weather_model');

Route::get('/projects/{id}', [Controller::class, 'index'])
    ->name('web_landing_page_project_edit');

Route::get('/projects/{id}/{type}/{weather}', [Controller::class, 'index'])
    ->name('web_landing_page_projects_edit_type_weather_model');

// Does not exist on UI, but good to catch
Route::get('/analyses', [Controller::class, 'index'])
    ->name('web_landing_page_analyses');

// Does not exist on UI, but good to catch
Route::get('/analyses/{id}', [Controller::class, 'index'])
    ->name('web_landing_page_analyses_id_report');

Route::get('/analyses/{id}/report', [Controller::class, 'index'])
    ->name('web_landing_page_analyses_report');




