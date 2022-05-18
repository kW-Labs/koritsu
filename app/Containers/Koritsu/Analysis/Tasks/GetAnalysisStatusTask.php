<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use ZipArchive;

/**
 * Class GetAnalysisStatusTask.
 *
 */
class GetAnalysisStatusTask extends Task {

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

    /**
     * @throws InternalErrorException
     * @throws UpdateResourceFailedException
     * @throws NotFoundException
     */
    public function run($analysis): array {

        // TODO: Check server is online / else error
        $host = $analysis->host;
        $status_url = "http://" . $host . ":8080/analyses/" . $analysis->openstudio_analysis_id . "/status.json";
        $response = Http::get($status_url);

        $data = ['status' => $response->json()];
        app(UpdateAnalysisTask::class)->run($data, $analysis->id);

        if (isset($data['status']['analysis']['status'])) {
            if ($data['status']['analysis']['status'] === 'completed') {
                if (isset($data['status']['analysis']['data_points'][0]['id'])) {
                    $data_point_id = $data['status']['analysis']['data_points'][0]['id'];
                    if ($data_point_id !== 'completed normal') {
                        $url = "http://" . $analysis->host . ":8080/data_points/" . $data_point_id . "/download_result_file?filename=in.osm";
                        $contents = file_get_contents($url);
                        $path = 'projects/' . $analysis->project_id . '/Base/results/in.osm';
                        Storage::disk('local')->put($path, $contents);

                        $zip_path = 'projects/' . $analysis->project_id .'/downloads/' . $data_point_id . '.zip';
                        if(!file_exists($zip_path)){
                            $url = "http://" . $analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=data_point.zip";
                            $contents = file_get_contents($url);
                            Storage::disk('local')->put($zip_path , $contents);
                        }

                        $url = "http://" . $analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=openstudio_results_report.html";
                        $contents = file_get_contents($url);
                        $report_save_path = 'projects/' . $analysis->project_id .'/downloads/' . $data_point_id . '.html';
                        Storage::disk('local')->put($report_save_path , $contents);
                    }
                }
            }
        }

        return $data;
    }

}

