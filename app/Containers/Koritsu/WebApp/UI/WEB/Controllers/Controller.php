<?php

namespace App\Containers\Koritsu\WebApp\UI\WEB\Controllers;

use App\Ship\Parents\Controllers\WebController;

class Controller extends WebController
{
    public function index()
    {
        return view('koritsu@webApp::public.index');
    }
}
