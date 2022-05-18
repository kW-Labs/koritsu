<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Exceptions\ProjectDoesNotBelongToUserException;
use App\Containers\Koritsu\Project\Models\Project;
use App\Containers\AppSection\User\Models\User;
use App\Ship\Parents\Tasks\Task;

/**
 * Class CheckIfProjectBelongsToUserTask
 *
 */
class CheckIfProjectBelongsToUserTask extends Task
{

    /**
     * @param User $user
     * @param Project $project
     *
     * @return bool
     * @throws ProjectDoesNotBelongToUserException
     */
    public function run(User $user, Project $project): bool
    {
        if ($user->id !== $project->user_id) {
            throw new ProjectDoesNotBelongToUserException();
        }

        return true;
    }
}
