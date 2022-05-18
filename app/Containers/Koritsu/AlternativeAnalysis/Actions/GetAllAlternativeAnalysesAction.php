<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\GetAllAlternativeAnalysesTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAllAlternativeAnalysisRequest;
use App\Ship\Parents\Actions\Action;

/**
 * Class GetAllAlternativeAnalysesAction.
 *
 */
class GetAllAlternativeAnalysesAction extends Action {

    /**
     * @param GetAllAlternativeAnalysisRequest $data
     * @return mixed
     */
    public function run(GetAllAlternativeAnalysisRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        return  app(GetAllAlternativeAnalysesTask::class)->run($user, $data->analysis_id);
    }
}
