<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use ZipArchive;

/**
 * Class GetAnalysisStatusTask.
 *
 */
class StopAnalysisTask extends Task {

    /**
     * @var  AnalysisRepository
     */
    protected AnalysisRepository $repository;

    /**
     * GetAllAnalysesTask constructor.
     *
     * @param AnalysisRepository $repository
     */
    public function __construct(AnalysisRepository $repository) {
        $this->repository = $repository;
    }

    public function run($analysis) {
        // TODO: Need try catch or throw error?
        $host = $analysis->host;
        $status_url = "http://" . $host . ":8080/analyses/" . $analysis->openstudio_analysis_id . "/stop";
        Http::get($status_url);
    }

}

