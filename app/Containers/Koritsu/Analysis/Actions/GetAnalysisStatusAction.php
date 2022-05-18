<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Containers\Koritsu\Analysis\Tasks\GetAnalysisStatusTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAnalysisStatusRequest;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class GetAllAnalysesAction.
 *
 */
class GetAnalysisStatusAction extends Action {

    /**
     * @param GetAnalysisStatusRequest $data
     * @return mixed
     * @throws NotFoundException
     */
    public function run(GetAnalysisStatusRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if (!$user) {
            throw new NotFoundException();
        }


        $analysis =  app(FindAnalysisByIdTask::class)->run($data->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        if($analysis->user_id == $user->id) {
            try {
                return app(GetAnalysisStatusTask::class)->run($analysis);
            } catch (InternalErrorException|UpdateResourceFailedException|NotFoundException $e) {
                return $e;
            }
        }else{
            throw new NotFoundException('You are not the owner of the Analysis');
        }
    }
}
