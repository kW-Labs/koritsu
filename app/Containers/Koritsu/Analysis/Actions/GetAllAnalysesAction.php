<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Tasks\GetAllAnalysesTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAllAnalysisRequest;
use App\Ship\Parents\Actions\Action;
use Prettus\Repository\Exceptions\RepositoryException;


/**
 * Class GetAllAnalysesAction.
 *
 */
class GetAllAnalysesAction extends Action {

    /**
     * @param GetAllAnalysisRequest $data
     * @return mixed
     * @throws RepositoryException
     */
    public function run(GetAllAnalysisRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        return app(GetAllAnalysesTask::class)->run($user, $data->project_id);
    }
}
