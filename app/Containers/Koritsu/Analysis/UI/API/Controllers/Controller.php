<?php

namespace App\Containers\Koritsu\Analysis\UI\API\Controllers;

use Apiato\Core\Exceptions\InvalidTransformerException;
use App\Containers\Koritsu\Analysis\Actions\CreateAnalysisAction;
use App\Containers\Koritsu\Analysis\Actions\FindAnalysisByIdAction;
use App\Containers\Koritsu\Analysis\Actions\GetAllAnalysesAction;
use App\Containers\Koritsu\Analysis\Actions\GetAnalysisReportAction;
use App\Containers\Koritsu\Analysis\Actions\GetAnalysisStatusAction;
use App\Containers\Koritsu\Analysis\Actions\GetDownloadAction;
use App\Containers\Koritsu\Analysis\Actions\RunAnalysisAction;
use App\Containers\Koritsu\Analysis\Actions\StopAnalysisByIdAction;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\Koritsu\Analysis\UI\API\Requests\CreateAnalysisRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\FindAnalysisByIdRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAllAnalysisRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAnalysisReportRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetAnalysisStatusRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\GetDownloadRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\RunAnalysisRequest;
use App\Containers\Koritsu\Analysis\UI\API\Requests\StopAnalysisByIdRequest;
use App\Containers\Koritsu\Analysis\UI\API\Transformers\AnalysisTransformer;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Controllers\ApiController;
use Illuminate\Support\Facades\Artisan;

/**
 * Class Controller
 *
 * @package App\Containers\Koritsu\Analysis\UI\API\Controllers
 */
class Controller extends ApiController
{
    /**
     * @param CreateAnalysisRequest $request
     * @return array
     * @throws NotFoundException
     */
    public function createAnalysis(CreateAnalysisRequest $request): array {

        return app(CreateAnalysisAction::class)->run($request);
    }

    /**
     * @param FindAnalysisByIdRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function findAnalysisById(FindAnalysisByIdRequest $request): array {

        $analysis = app(FindAnalysisByIdAction::class)->run($request);
        return $this->transform($analysis, AnalysisTransformer::class);
    }

    /**
     * @param GetAllAnalysisRequest $request
     * @return array
     * @throws InvalidTransformerException
     */
    public function getAllAnalyses(GetAllAnalysisRequest $request): array {

        $analysis = app(GetAllAnalysesAction::class)->run($request);
        return $this->transform($analysis, AnalysisTransformer::class);
    }

    /**
     * @param GetAnalysisReportRequest $request
     * @return object
     * @throws NotFoundException
     */
    public function getReport(GetAnalysisReportRequest $request): object {

        return app(GetAnalysisReportAction::class)->run($request);
    }


    /**
     * @param GetAnalysisStatusRequest $request
     * @return array
     * @throws NotFoundException
     */
    public function getStatus(GetAnalysisStatusRequest $request): array {

        return app(GetAnalysisStatusAction::class)->run($request);
    }

    /**
     * @throws NotFoundException
     */
    public function getDownload(GetDownloadRequest $request) {

        return app(GetDownloadAction::class)->run($request);
    }


    public function createAlternative(Analysis $analysis): string {

        Artisan::call('openstudio:base', ['analysis' => $analysis->id]);
        return Artisan::output();
    }

    /**
     * @param StopAnalysisByIdRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function stopAnalysisById(StopAnalysisByIdRequest $request): array {

        $analysis = app(StopAnalysisByIdAction::class)->run($request);
        return $this->transform($analysis, AnalysisTransformer::class);
    }


    /**
     * @param RunAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function runAnalysisById(RunAnalysisRequest $request): array {

        $analysis = app(RunAnalysisAction::class)->run($request);
        return $this->transform($analysis, AnalysisTransformer::class);
    }

}
