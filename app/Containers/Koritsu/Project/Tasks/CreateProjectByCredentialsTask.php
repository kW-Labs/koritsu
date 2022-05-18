<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Models\Project;
use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class CreateProjectByCredentialsTask.
 *
 */
class CreateProjectByCredentialsTask extends Task {

    /**
     * @param integer $user_id
     * @param string|null $data
     *
     * @return  mixed
     * @throws  CreateResourceFailedException
     * @throws \Apiato\Core\Abstracts\Exceptions\Exception
     */
    public function run(
        int $user_id,
        string $data
    ): Project {

        try {

            $project = $this->repository->create([
                'user_id' => $user_id,
                'data' => $data
            ]);

        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        return $project;
    }

    protected ProjectRepository $repository;

    public function __construct(ProjectRepository $repository) {
        $this->repository = $repository;
    }

}
