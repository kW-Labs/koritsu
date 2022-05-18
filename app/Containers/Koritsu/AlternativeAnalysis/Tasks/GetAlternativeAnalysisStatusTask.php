<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;


/**
 * Class GetAlternativeAnalysisStatusTask.
 *
 */
class GetAlternativeAnalysisStatusTask extends Task
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
     * @throws InternalErrorException
     * @throws UpdateResourceFailedException
     * @throws NotFoundException
     */
    public function run($alternative_analysis): array {

        $host = $alternative_analysis->host;
        $status_url = "http://" . $host . ":8080/analyses/"  .  $alternative_analysis->openstudio_analysis_id . "/status.json";
        $response = Http::get($status_url);

        $data = ['status' => $response->json()];

        if (isset($data['status']['analysis']['status'])) {
            app(UpdateAlternativeAnalysisTask::class)->run($data, $alternative_analysis);
            if ($data['status']['analysis']['status'] === 'completed') {
                if (isset($data['status']['analysis']['data_points'][0]['id'])) {
                    $data_point_id = $data['status']['analysis']['data_points'][0]['id'];
                    if ($data_point_id !== 'completed normal') {
                        $url = "http://" . $alternative_analysis->host . ":8080/data_points/" . $data_point_id . "/download_result_file?filename=in.osm";
                        $contents = file_get_contents($url);
                        $path = 'projects/' . $alternative_analysis->analysis->project_id . '/Base/results/in_' . $alternative_analysis->openstudio_analysis_id . '.osm';
                        Storage::disk('local')->put($path, $contents);

                        $zip_path = 'projects/' . $alternative_analysis->analysis->project_id .'/downloads/' . $data_point_id . '.zip';
                        if(!file_exists($zip_path)){
                            $url = "http://" . $alternative_analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=data_point.zip";
                            $contents = file_get_contents($url);
                            Storage::disk('local')->put($zip_path , $contents);
                        }

                        $url = "http://" . $alternative_analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=openstudio_results_report.html";
                        $contents = file_get_contents($url);
                        $report_save_path = 'projects/' . $alternative_analysis->analysis->project_id .'/downloads/' . $data_point_id . '.html';
                        Storage::disk('local')->put($report_save_path , $contents);
                    }
                }
            }
        }

        return $data;
    }


}
