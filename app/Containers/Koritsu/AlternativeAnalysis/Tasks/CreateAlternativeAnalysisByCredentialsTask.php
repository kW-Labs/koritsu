<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;

/**
 * Class CreateAlternativeAnalysisByCredentialsTask.
 *
 */
class CreateAlternativeAnalysisByCredentialsTask extends Task {

    /**
     * @param integer $user_id
     * @param integer $analysis_id
     * @param string $name
     * @return  mixed
     * @throws CreateResourceFailedException
     * @throws \Apiato\Core\Abstracts\Exceptions\Exception
     */
    public function run(
        int $user_id,
        int $analysis_id,
        string $name
    ): AlternativeAnalysis {

        try {

            $alternative_analysis = $this->repository->create([
                'user_id' => $user_id,
                'name' => $name,
                'ran_analysis' => false,
                'analysis_id' => $analysis_id,
            ]);

        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        return $alternative_analysis;
    }

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

}
