<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class FindAnalysisByIdTask.
 *
 */
class FindAnalysisByIdTask extends Task
{

    protected AnalysisRepository $repository;

    public function __construct(AnalysisRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @param $analysisId
     *
     * @return Analysis
     * @throws NotFoundException
     */
    public function run($analysisId): Analysis
    {
        try {
            $analysis = $this->repository->find($analysisId);
        } catch (Exception $e) {
            throw new NotFoundException();
        }

        return $analysis;
    }

}
