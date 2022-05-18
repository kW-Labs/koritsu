<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use Apiato\Core\Abstracts\Exceptions\Exception;
use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Exceptions\AnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\Koritsu\Analysis\Tasks\CheckIfAnalysisBelongsToUserTask;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Containers\Koritsu\Analysis\Tasks\RunAnalysisTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\RunAnalysisRequest;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class FindUserByIdAction.
 *
 */
class RunAnalysisAction extends Action {

    /**
     * @param RunAnalysisRequest $request
     *
     * @return Exception|Analysis|CreateResourceFailedException|InternalErrorException|NotFoundException|\Exception
     * @throws NotFoundException
     * @throws AnalysisDoesNotBelongToUserException
     */
    public function run(RunAnalysisRequest $request) {

        $analysis =  app(FindAnalysisByIdTask::class)->run($request->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        app(CheckIfAnalysisBelongsToUserTask::class)->run($user, $analysis);

        try {
            return app(RunAnalysisTask::class)->run($analysis);
        } catch (CreateResourceFailedException|NotFoundException|InternalErrorException|Exception $e) {
            return $e;
        }
    }

}
