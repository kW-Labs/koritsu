<?php

namespace App\Containers\Koritsu\Analysis\Actions;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Containers\Koritsu\Analysis\Tasks\GetAnalysisReportTask;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAnalysisReportRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;
use Illuminate\Contracts\Filesystem\FileNotFoundException;


/**
 * Class GetAllAnalysesReportAction.
 *
 */
class GetAnalysisReportAction extends Action {

    /**
     * @param GetAnalysisReportRequest $request
     * @return mixed
     * @throws NotFoundException|FileNotFoundException
     */
    public function run(GetAnalysisReportRequest $request) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if (!$user) {
            throw new NotFoundException();
        }


        $analysis =  app(FindAnalysisByIdTask::class)->run($request->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        if($analysis->user_id == $user->id) {
            return  app(GetAnalysisReportTask::class)->run($analysis);
        }else{
            throw new NotFoundException('You are not the owner of the Analysis');
        }

    }
}
