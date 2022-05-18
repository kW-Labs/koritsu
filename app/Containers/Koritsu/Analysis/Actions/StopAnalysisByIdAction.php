<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Exceptions\AnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\Koritsu\Analysis\Tasks\CheckIfAnalysisBelongsToUserTask;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Containers\Koritsu\Analysis\Tasks\StopAnalysisTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\StopAnalysisByIdRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class FindUserByIdAction.
 *
 */
class StopAnalysisByIdAction extends Action {

    /**
     * @param StopAnalysisByIdRequest $request
     *
     * @return  Analysis
     * @throws NotFoundException
     * @throws AnalysisDoesNotBelongToUserException
     */
    public function run(StopAnalysisByIdRequest $request): Analysis {

        $analysis =  app(FindAnalysisByIdTask::class)->run($request->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if($user->hasRole('admin')){
            return $analysis;
        }

        app(CheckIfAnalysisBelongsToUserTask::class)->run($user, $analysis);

        app(StopAnalysisTask::class)->run($analysis);

        return $analysis;
    }

}
