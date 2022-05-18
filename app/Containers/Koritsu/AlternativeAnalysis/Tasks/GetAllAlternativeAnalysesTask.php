<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Criterias\AlternativeAnalysisIdAndUserIdCriteria;
use App\Containers\Koritsu\AlternativeAnalysis\Data\Criterias\AlternativeAnalysisIdCriteria;
use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Ship\Parents\Tasks\Task;
use Prettus\Repository\Exceptions\RepositoryException;

/**
 * Class GetAllAnalysesTask.
 *
 */
class GetAllAlternativeAnalysesTask extends Task
{

    /**
     * @var  AlternativeAnalysisRepository
     */
    protected AlternativeAnalysisRepository $repository;

    /**
     * GetAllAnalysesTask constructor.
     *
     * @param AlternativeAnalysisRepository $repository
     */
    public function __construct(AlternativeAnalysisRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @throws RepositoryException
     */
    public function run($user, $analysisId)
    {

        if(!$user->hasRole('admin')){
            $this->repository->pushCriteria(new AlternativeAnalysisIdCriteria($analysisId));
        }else{
            $this->repository->pushCriteria(new AlternativeAnalysisIdAndUserIdCriteria($analysisId, $user->id));
        }

        return $this->repository->paginate();
    }


}
