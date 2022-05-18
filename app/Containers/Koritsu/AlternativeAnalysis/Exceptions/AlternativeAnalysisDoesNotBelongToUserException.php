<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Exceptions;

use App\Ship\Parents\Exceptions\Exception;
use Symfony\Component\HttpFoundation\Response;

class AlternativeAnalysisDoesNotBelongToUserException extends Exception
{
    public int $httpStatusCode = Response::HTTP_CONFLICT;

    public $message = 'The selected AlternativeAnalysis does not belong to the current Project or User.';
}
