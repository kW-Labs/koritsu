<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\Koritsu\Analysis\Jobs\CreateOpenStudioBaselineJob;
use App\Containers\Koritsu\Analysis\UI\API\Requests\CreateAnalysisRequest;
use App\Containers\Koritsu\Project\Tasks\FindProjectByIdTask;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class RegisterUserAction.
 *
 */
class CreateAnalysisAction extends Action {

    /**
     * @param CreateAnalysisRequest $reqeust
     *
     * @return array
     * @throws NotFoundException
     */
    public function run(CreateAnalysisRequest $reqeust): array {

        $project =  app(FindProjectByIdTask::class)->run($reqeust->project_id);
        if (!$project) {
            throw new NotFoundException();
        }

        // TODO: Verify no other analysis is running on any server, continue or fail
        dispatch(new CreateOpenStudioBaselineJob($project));

        return ['success' => true, 'status' => 'Job Sent to Queue!!!'];
    }
}
