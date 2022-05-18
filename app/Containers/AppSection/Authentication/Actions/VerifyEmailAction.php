<?php

namespace App\Containers\AppSection\Authentication\Actions;

use App\Containers\AppSection\Authentication\Notifications\EmailVerified;
use App\Containers\AppSection\User\Tasks\FindUserByIdTask;
use App\Containers\AppSection\Authentication\UI\API\Requests\VerifyEmailRequest;
use App\Ship\Parents\Actions\Action;

class VerifyEmailAction extends Action {
    public function run(VerifyEmailRequest $request) {
        $user = app(FindUserByIdTask::class)->run($request->id);
        if (!$user->hasVerifiedEmail()) {

            if ($this->isHashEqualsUserEmail($request->hash, $user)) {
                $user->markEmailAsVerified();
                return route('web_landing_page_verified_email');
            }
        }

        return route('web_landing_page_login');

    }

    protected function isHashEqualsUserEmail($hash, $user): bool {
        return hash_equals((string) $hash, sha1($user->getEmailForVerification()));
    }

}
