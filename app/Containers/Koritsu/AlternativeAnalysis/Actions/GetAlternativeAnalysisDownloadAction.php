<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAlternativeAnalysisDownloadRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;
use Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Class GetDownloadAction.
 *
 */
class GetAlternativeAnalysisDownloadAction extends Action {

    /**
     * @param GetAlternativeAnalysisDownloadRequest $data
     * @return array|StreamedResponse
     * @throws NotFoundException
     */
    public function run(GetAlternativeAnalysisDownloadRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if (!$user) {
            throw new NotFoundException();
        }

        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($data->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();
        }

        $status = json_decode($alternative_analysis->status,true);
        $data_point_id = $status['analysis']['data_points'][0]['id'];

        if($data->file == "openstudio_report") {
            $report_save_path = 'projects/' . $alternative_analysis->analysis->project_id . '/downloads/' . $data_point_id . '.html';
        }else{
            $report_save_path = 'projects/' . $alternative_analysis->analysis->project_id . '/downloads/' . $data_point_id . '.zip';
        }

        if(Storage::disk('local')->exists($report_save_path)){
            return Storage::download(  $report_save_path);
        }

        return [];
    }
}
