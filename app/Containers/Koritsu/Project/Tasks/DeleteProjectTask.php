<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Exceptions\DeleteResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Storage;

/**
 * Class DeleteProjectTask
 *
 */
class DeleteProjectTask extends Task
{

    protected ProjectRepository $repository;

    public function __construct(ProjectRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     *
     * @param Project $project
     *
     * @return bool
     * @throws DeleteResourceFailedException
     */
    public function run(Project $project): bool {
        try {
            $project_path = 'projects/' . $project->id;
            Storage::deleteDirectory($project_path);

            return $this->repository->delete($project->id);
        }
        catch (Exception $exception) {
            throw new DeleteResourceFailedException();
        }
    }
}
