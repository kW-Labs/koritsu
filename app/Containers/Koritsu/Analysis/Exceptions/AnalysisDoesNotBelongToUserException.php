<?php

namespace App\Containers\Koritsu\Analysis\Exceptions;

use App\Ship\Parents\Exceptions\Exception;
use Symfony\Component\HttpFoundation\Response;

class AnalysisDoesNotBelongToUserException extends Exception
{
    public int $httpStatusCode = Response::HTTP_CONFLICT;

    public $message = 'The selected Analysis does not belong to the current Project or User.';
}
