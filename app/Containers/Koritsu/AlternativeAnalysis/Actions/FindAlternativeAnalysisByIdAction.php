<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Exceptions\AlternativeAnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CheckIfAlternativeAnalysisBelongsToUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\FindAlternativeAnalysisByIdRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class FindUserByIdAction.
 *
 */
class FindAlternativeAnalysisByIdAction extends Action {

    /**
     * @param FindAlternativeAnalysisByIdRequest $request
     *
     * @return  AlternativeAnalysis
     * @throws NotFoundException
     * @throws AlternativeAnalysisDoesNotBelongToUserException
     */
    public function run(FindAlternativeAnalysisByIdRequest $request): AlternativeAnalysis {

        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($request->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if($user->hasRole('admin')){
            return $alternative_analysis;
        }

        app(CheckIfAlternativeAnalysisBelongsToUserTask::class)->run($user, $alternative_analysis);

        return $alternative_analysis;
    }

}
