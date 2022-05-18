<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\GetAlternativeAnalysisStatusTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAlternativeAnalysisStatusRequest;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class GetAllAnalysesAction.
 *
 */
class GetAlternativeAnalysisStatusAction extends Action {

    /**
     * @param GetAlternativeAnalysisStatusRequest $data
     * @return mixed
     * @throws NotFoundException
     */
    public function run(GetAlternativeAnalysisStatusRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if (!$user) {
            throw new NotFoundException();
        }

        $analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($data->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        if($analysis->user_id == $user->id) {
            try {
                return app(GetAlternativeAnalysisStatusTask::class)->run($analysis);
            } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {
                return $e;
            }
        }else{
            throw new NotFoundException('You are not the owner of the AlternativeAnalysis');
        }
    }
}
