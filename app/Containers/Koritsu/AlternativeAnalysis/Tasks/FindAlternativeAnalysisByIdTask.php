<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class FindAlternativeAnalysisByIdTask.
 *
 */
class FindAlternativeAnalysisByIdTask extends Task
{

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @param $alternative_analysis_id
     *
     * @return AlternativeAnalysis
     * @throws NotFoundException
     */
    public function run($alternative_analysis_id): AlternativeAnalysis
    {
        try {
            $alternative_analysis = $this->repository->find($alternative_analysis_id);
        } catch (Exception $e) {
            throw new NotFoundException();
        }

        return $alternative_analysis;
    }

}
