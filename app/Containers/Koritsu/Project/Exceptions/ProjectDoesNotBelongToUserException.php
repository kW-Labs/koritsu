<?php

namespace App\Containers\Koritsu\Project\Exceptions;

use App\Ship\Parents\Exceptions\Exception;
use Symfony\Component\HttpFoundation\Response;

class ProjectDoesNotBelongToUserException extends Exception
{
    public int $httpStatusCode = Response::HTTP_CONFLICT;

    public $message = 'The selected Project does not belong to the current User.';
}
