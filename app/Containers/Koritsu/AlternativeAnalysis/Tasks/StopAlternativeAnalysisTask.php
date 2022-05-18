<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Support\Facades\Http;


/**
 * Class GetAnalysisStatusTask.
 *
 */
class StopAlternativeAnalysisTask extends Task {

    /**
     * @var  AlternativeAnalysisRepository
     */
    protected AlternativeAnalysisRepository $repository;

    /**
     * GetAllAnalysesTask constructor.
     *
     * @param AlternativeAnalysisRepository $repository
     */
    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

    public function run($alternative_analysis) {
        // TODO: Need try catch or throw error?
        $host = $alternative_analysis->host;
        $status_url = "http://" . $host . ":8080/analyses/" . $alternative_analysis->openstudio_analysis_id . "/stop";
        Http::get($status_url);
    }

}

