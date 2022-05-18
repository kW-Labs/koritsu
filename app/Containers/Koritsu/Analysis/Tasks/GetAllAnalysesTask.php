<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Data\Criterias\ProjectIdAndUserIdCriteria;
use App\Containers\Koritsu\Analysis\Data\Criterias\ProjectIdCriteria;
use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Ship\Parents\Tasks\Task;
use Prettus\Repository\Exceptions\RepositoryException;

/**
 * Class GetAllAnalysesTask.
 *
 */
class GetAllAnalysesTask extends Task
{

    /**
     * @var  AnalysisRepository
     */
    protected AnalysisRepository $repository;

    /**
     * GetAllAnalysesTask constructor.
     *
     * @param AnalysisRepository $repository
     */
    public function __construct(AnalysisRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @throws RepositoryException
     */
    public function run($user, $projectId)
    {

        if(!$user->hasRole('admin')){
            $this->repository->pushCriteria(new ProjectIdCriteria($projectId));
        }else{
            $this->repository->pushCriteria(new ProjectIdAndUserIdCriteria($projectId, $user->id));
        }

        return $this->repository->paginate();
    }


}
