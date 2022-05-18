<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Ship\Exceptions\DeleteResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class DeleteProjectTask
 *
 */
class DeleteAlternativeAnalysisTask extends Task
{

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     *
     * @param AlternativeAnalysis $alternative_analysis
     *
     * @return bool
     * @throws DeleteResourceFailedException
     */
    public function run(AlternativeAnalysis $alternative_analysis): bool {
        try {
            return $this->repository->delete($alternative_analysis->id);
        }
        catch (Exception $exception) {
            throw new DeleteResourceFailedException();
        }
    }
}
