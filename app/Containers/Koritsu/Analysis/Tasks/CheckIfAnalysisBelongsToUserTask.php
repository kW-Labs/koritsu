<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Exceptions\AnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\AppSection\User\Models\User;
use App\Ship\Parents\Tasks\Task;

/**
 * Class CheckIfAnalysisBelongsToUserTask
 *
 */
class CheckIfAnalysisBelongsToUserTask extends Task
{

    /**
     * @param User $user
     * @param Analysis $analysis
     *
     * @return bool
     * @throws AnalysisDoesNotBelongToUserException
     */
    public function run(User $user, Analysis $analysis): bool
    {
        if ($user->id !== $analysis->user_id) {
            throw new AnalysisDoesNotBelongToUserException();
        }

        return true;
    }
}
