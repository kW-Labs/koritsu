<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Data\Criterias\UserIdCriteria;
use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Ship\Parents\Tasks\Task;
use Prettus\Repository\Exceptions\RepositoryException;

/**
 * Class GetAllProjectsTask.
 *
 */
class GetAllProjectsTask extends Task
{

    /**
     * @var  ProjectRepository
     */
    protected ProjectRepository $repository;

    /**
     * GetAllProjectsTask constructor.
     *
     * @param ProjectRepository $repository
     */
    public function __construct(ProjectRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @throws RepositoryException
     */
    public function run($user)
    {

        if(!$user->hasRole('admin')){
            $this->repository->pushCriteria(new UserIdCriteria($user->id));
        }

        return $this->repository->paginate();
    }


}
