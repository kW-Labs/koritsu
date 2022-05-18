<?php

namespace App\Containers\Koritsu\Project\Actions;

use Apiato\Core\Abstracts\Exceptions\Exception;
use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Project\Models\Project;
use App\Containers\Koritsu\Project\Tasks\CreateProjectByCredentialsTask;
use App\Containers\Koritsu\Project\UI\API\Requests\CreateProjectRequest;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class RegisterUserAction.
 *
 */
class CreateProjectAction extends Action {

    /**
     * @param CreateProjectRequest $request
     *
     * @return  Project
     * @throws CreateResourceFailedException
     * @throws Exception
     */
    public function run(CreateProjectRequest $request): Project {

        $user =  app(GetAuthenticatedUserTask::class)->run();

        // TODO: validate json
        return app(CreateProjectByCredentialsTask::class)->run(
            $user->id,
            json_encode($request->data)
        );
    }
}
