<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Exceptions\AlternativeAnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\AppSection\User\Models\User;
use App\Ship\Parents\Tasks\Task;

/**
 * Class CheckIfAlternativeAnalysisBelongsToUserTask
 *
 */
class CheckIfAlternativeAnalysisBelongsToUserTask extends Task
{

    /**
     * @param User $user
     * @param AlternativeAnalysis $analysis
     *
     * @return bool
     * @throws AlternativeAnalysisDoesNotBelongToUserException
     */
    public function run(User $user, AlternativeAnalysis $analysis): bool
    {
        if ($user->id !== $analysis->user_id) {
            throw new AlternativeAnalysisDoesNotBelongToUserException();
        }

        return true;
    }
}
