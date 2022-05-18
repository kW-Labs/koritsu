<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\UpdateAlternativeAnalysisTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\UpdateAlternativeAnalysisRequest;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Actions\Action;

/**
 * Class UpdateAlternativeAnalysisAction.
 *
 */
class UpdateAlternativeAnalysisAction extends Action {

    /**
     * @param UpdateAlternativeAnalysisRequest $request
     *
     * @return AlternativeAnalysis|InternalErrorException|NotFoundException|UpdateResourceFailedException|\Exception
     * @throws NotFoundException
     */
    public function run(UpdateAlternativeAnalysisRequest $request) {

        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($request->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();

        }

        $request = $request->sanitizeInput([
            'name'
        ]);

        try {
            return app(UpdateAlternativeAnalysisTask::class)->run($request, $alternative_analysis);
        } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {
            return $e;
        }
    }
}
