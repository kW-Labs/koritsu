<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class FindProjectByIdTask.
 *
 */
class FindProjectByIdTask extends Task
{

    protected ProjectRepository $repository;

    public function __construct(ProjectRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @param $projectId
     *
     * @return Project
     * @throws NotFoundException
     */
    public function run($projectId): Project
    {
        try {
            $project = $this->repository->find($projectId);
        } catch (Exception $e) {
            throw new NotFoundException();
        }

        return $project;
    }

}
