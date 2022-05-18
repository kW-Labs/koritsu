<?php

namespace App\Containers\Koritsu\Project\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Project\Tasks\GetAllProjectsTask;
use App\Ship\Parents\Actions\Action;

/**
 * Class GetAllProjectsAction.
 *
 */
class GetAllProjectsAction extends Action {

    /**
     * @return mixed
     */
    public function run($request) {
        $user =  app(GetAuthenticatedUserTask::class)->run();

        return app(GetAllProjectsTask::class)->run($user);
    }
}
