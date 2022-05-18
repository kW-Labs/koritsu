<?php

namespace App\Containers\Koritsu\Project\Actions;

use App\Containers\Koritsu\Project\Models\Project;
use App\Containers\Koritsu\Project\Tasks\FindProjectByIdTask;
use App\Containers\Koritsu\Project\Tasks\UpdateProjectTask;
use App\Containers\Koritsu\Project\UI\API\Requests\UpdateProjectRequest;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class UpdateUserAction.
 *
 */
class UpdateProjectAction extends Action {

    /**
     * @param UpdateProjectRequest $request
     *
     * @return Project|InternalErrorException|NotFoundException|UpdateResourceFailedException|\Exception
     * @throws NotFoundException
     */
    public function run(UpdateProjectRequest $request) {

        $project =  app(FindProjectByIdTask::class)->run($request->id);
        if (!$project) {
            throw new NotFoundException();
        }

        $request = $request->sanitizeInput([
            'data'
        ]);

        // TODO: Always For Re-run on Project Update ?
        try {
            return app(UpdateProjectTask::class)->run($request, $project->id, true);
        } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {
            return $e;
        }
    }
}
