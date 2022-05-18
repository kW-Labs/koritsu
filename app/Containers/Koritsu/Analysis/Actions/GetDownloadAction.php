<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetDownloadRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;
use Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Class GetDownloadAction.
 *
 */
class GetDownloadAction extends Action {

    /**
     * @param GetDownloadRequest $data
     * @return array|StreamedResponse
     * @throws NotFoundException
     */
    public function run(GetDownloadRequest $data) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if (!$user) {
            throw new NotFoundException();
        }

        $analysis =  app(FindAnalysisByIdTask::class)->run($data->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        $status = json_decode($analysis->status,true);
        $data_point_id = $status['analysis']['data_points'][0]['id'];

        if($data->file == "openstudio_report") {
            $report_save_path = 'projects/' . $analysis->project_id . '/downloads/' . $data_point_id . '.html';
        }else{
            $report_save_path = 'projects/' . $analysis->project_id . '/downloads/' . $data_point_id . '.zip';
        }

        if(Storage::disk('local')->exists($report_save_path)){
            return Storage::download(  $report_save_path);
        }

        return [];
    }
}
