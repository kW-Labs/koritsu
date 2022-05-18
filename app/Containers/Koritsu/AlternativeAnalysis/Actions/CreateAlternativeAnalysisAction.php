<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use Apiato\Core\Abstracts\Exceptions\Exception;
use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CreateAlternativeAnalysisByCredentialsTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\CreateAlternativeAnalysisRequest;
use App\Containers\Koritsu\Analysis\Tasks\FindAnalysisByIdTask;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class CreateAlternativeAnalysisAction.
 *
 */
class CreateAlternativeAnalysisAction extends Action {

    /**
     * @param CreateAlternativeAnalysisRequest $request
     *
     * @return Exception|AlternativeAnalysis|CreateResourceFailedException|\Exception
     * @throws NotFoundException
     */
    public function run(CreateAlternativeAnalysisRequest $request) {

        $user =  app(GetAuthenticatedUserTask::class)->run();
        $analysis =  app(FindAnalysisByIdTask::class)->run($request->id);
        if (!$analysis) {
            throw new NotFoundException();
        }

        // TODO: Verify no other analysis is running on any server, continue or fail
        try {
            $analysis = app(CreateAlternativeAnalysisByCredentialsTask::class)->run(
                $user->id,
                $analysis->id,
                $request->name
            );
        } catch (CreateResourceFailedException|Exception $e) {
            return $e;
        }

        return $analysis;
    }
}
