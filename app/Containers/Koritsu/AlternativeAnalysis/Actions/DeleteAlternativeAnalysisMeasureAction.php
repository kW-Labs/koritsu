<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Exceptions\AlternativeAnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CheckIfAlternativeAnalysisBelongsToUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\DeleteAlternativeAnalysisMeasureTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\DeleteAlternativeAnalysisMeasureRequest;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class DeleteAlternativeAnalysisActionAction.
 *
 * @author Mahmoud Zalt <mahmoud@zalt.me> nm
 */
class DeleteAlternativeAnalysisMeasureAction extends Action {

    /**
     * @param DeleteAlternativeAnalysisMeasureRequest $request
     * @throws NotFoundException
     * @throws AlternativeAnalysisDoesNotBelongToUserException
     */
    public function run(DeleteAlternativeAnalysisMeasureRequest $request): void {
        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($request->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        app(CheckIfAlternativeAnalysisBelongsToUserTask::class)->run($user, $alternative_analysis);

        $request = $request->sanitizeInput([
            'name'
        ]);

        try {
            app(DeleteAlternativeAnalysisMeasureTask::class)->run($request, $alternative_analysis);
        } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {
        }
    }
}
