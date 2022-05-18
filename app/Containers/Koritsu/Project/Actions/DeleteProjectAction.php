<?php

namespace App\Containers\Koritsu\Project\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Tasks\UpdateAnalysisTask;
use App\Containers\Koritsu\Project\Exceptions\ProjectDoesNotBelongToUserException;
use App\Containers\Koritsu\Project\Tasks\CheckIfProjectBelongsToUserTask;
use App\Containers\Koritsu\Project\Tasks\DeleteProjectTask;
use App\Containers\Koritsu\Project\Tasks\FindProjectByIdTask;
use App\Containers\Koritsu\Project\Tasks\UpdateProjectTask;
use App\Containers\Koritsu\Project\UI\API\Requests\DeleteProjectRequest;
use App\Ship\Exceptions\DeleteResourceFailedException;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class DeleteUserAction.
 *
 */
class DeleteProjectAction extends Action {

    /**
     * @param DeleteProjectRequest $request
     * @throws NotFoundException
     * @throws DeleteResourceFailedException|ProjectDoesNotBelongToUserException
     */
    public function run(DeleteProjectRequest $request): void {
        $user =  app(GetAuthenticatedUserTask::class)->run();

        $project =  app(FindProjectByIdTask::class)->run($request->id);
        if (!$project) {
            throw new NotFoundException();
        }

        if(!$user->hasRole('admin')){
            app(CheckIfProjectBelongsToUserTask::class)->run($user, $project);
        }

        if($project->analysis_id) {
            $current_analysis_id = $project->analysis_id;
            $request = ['analysis_id' => null];
            try {
                app(UpdateProjectTask::class)->run($request, $project->id);
            } catch (InternalErrorException|UpdateResourceFailedException|NotFoundException $e) {

            }

            $request = ['project_id' => null];
            try {
                app(UpdateAnalysisTask::class)->run($request, $current_analysis_id);
            } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {
            }
        }

        app(DeleteProjectTask::class)->run($project);
    }
}
