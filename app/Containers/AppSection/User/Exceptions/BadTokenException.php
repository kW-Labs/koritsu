<?php

namespace App\Containers\AppSection\User\Exceptions;

use App\Ship\Parents\Exceptions\Exception;
use Symfony\Component\HttpFoundation\Response;

class BadTokenException extends Exception
{
    protected $code = Response::HTTP_NOT_FOUND;
    protected $message = 'Invalid Token. Please requests a new forgot password email.';
}
