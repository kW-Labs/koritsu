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
class CopyAlternativeAnalysisTask extends Task {

    /**
     * @param $alternative_analysis
     * @return  mixed
     * @throws \Apiato\Core\Abstracts\Exceptions\Exception
     * @throws CreateResourceFailedException
     */
    public function run($alternative_analysis ): AlternativeAnalysis {

        try {

            $clone_alternative_analysis = $this->repository->create([
                'user_id' => $alternative_analysis->user_id,
                'name' => $alternative_analysis->name . " Copy",
                'ran_analysis' => false,
                'data' => $alternative_analysis->data,
                'host' => $alternative_analysis->host,
                'analysis_id' => $alternative_analysis->analysis_id,
            ]);

        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        return $clone_alternative_analysis;
    }

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

}
