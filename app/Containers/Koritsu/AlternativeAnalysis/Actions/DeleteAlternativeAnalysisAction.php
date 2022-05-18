<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Exceptions\AlternativeAnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CheckIfAlternativeAnalysisBelongsToUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\DeleteAlternativeAnalysisTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\DeleteAlternativeAnalysisRequest;
use App\Ship\Exceptions\DeleteResourceFailedException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class DeleteAlternativeAnalysisActionAction.
 *
 * @author Mahmoud Zalt <mahmoud@zalt.me>
 */
class DeleteAlternativeAnalysisAction extends Action {

    /**
     * @param DeleteAlternativeAnalysisRequest $request
     * @throws NotFoundException
     * @throws AlternativeAnalysisDoesNotBelongToUserException
     * @throws DeleteResourceFailedException
     */
    public function run(DeleteAlternativeAnalysisRequest $request): void {
        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($request->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        app(CheckIfAlternativeAnalysisBelongsToUserTask::class)->run($user, $alternative_analysis);


        app(DeleteAlternativeAnalysisTask::class)->run($alternative_analysis);
    }
}
