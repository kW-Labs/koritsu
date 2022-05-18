<?php

namespace App\Containers\Koritsu\Project\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Project\Exceptions\ProjectDoesNotBelongToUserException;
use App\Containers\Koritsu\Project\Models\Project;
use App\Containers\Koritsu\Project\Tasks\CheckIfProjectBelongsToUserTask;
use App\Containers\Koritsu\Project\Tasks\FindProjectByIdTask;
use App\Containers\Koritsu\Project\UI\API\Requests\FindProjectByIdRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class FindUserByIdAction.
 *
 */
class FindProjectByIdAction extends Action {

    /**
     * @param FindProjectByIdRequest $request
     *
     * @return  Project
     * @throws NotFoundException
     * @throws ProjectDoesNotBelongToUserException
     */
    public function run(FindProjectByIdRequest $request): Project {

        $project = app(FindProjectByIdTask::class)->run($request->id);
        if (!$project) {
            throw new NotFoundException();
        }

        $user = app(GetAuthenticatedUserTask::class)->run();
        if($user->hasRole('admin')){
            return $project;
        }

        app(CheckIfProjectBelongsToUserTask::class)->run($user, $project);

        return $project;
    }

}
