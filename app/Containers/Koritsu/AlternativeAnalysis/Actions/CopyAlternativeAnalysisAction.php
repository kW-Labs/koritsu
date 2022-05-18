<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Actions;

use Apiato\Core\Abstracts\Exceptions\Exception;
use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Exceptions\AlternativeAnalysisDoesNotBelongToUserException;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CheckIfAlternativeAnalysisBelongsToUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\CopyAlternativeAnalysisTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\FindAlternativeAnalysisByIdTask;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\CopyAlternativeAnalysisRequest;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class FindUserByIdAction.
 *
 */
class CopyAlternativeAnalysisAction extends Action {

    /**
     * @param CopyAlternativeAnalysisRequest $request
     *
     * @return Exception|AlternativeAnalysis|CreateResourceFailedException|\Exception
     * @throws NotFoundException
     * @throws AlternativeAnalysisDoesNotBelongToUserException
     */
    public function run(CopyAlternativeAnalysisRequest $request) {

        $alternative_analysis =  app(FindAlternativeAnalysisByIdTask::class)->run($request->id);
        if (!$alternative_analysis) {
            throw new NotFoundException();
        }

        $user =  app(GetAuthenticatedUserTask::class)->run();
        if($user->hasRole('admin')){
            return $alternative_analysis;
        }

        app(CheckIfAlternativeAnalysisBelongsToUserTask::class)->run($user, $alternative_analysis);

        try {
            return app(CopyAlternativeAnalysisTask::class)->run($alternative_analysis);
        } catch (CreateResourceFailedException|Exception $e) {
            return $e;
        }
    }

}
