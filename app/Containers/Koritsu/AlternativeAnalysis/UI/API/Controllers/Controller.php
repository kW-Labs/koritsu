<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers;

use Apiato\Core\Exceptions\InvalidTransformerException;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\CopyAlternativeAnalysisAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\CreateAlternativeAnalysisAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\DeleteAlternativeAnalysisAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\DeleteAlternativeAnalysisMeasureAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\FindAlternativeAnalysisByIdAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\GetAllAlternativeAnalysesAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\GetAlternativeAnalysisStatusAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\GetAlternativeAnalysisDownloadAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\RunAlternativeAnalysisAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\UpdateAlternativeAnalysisAction;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\UpdateAlternativeAnalysisMeasuresAction;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\CopyAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\CreateAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\DeleteAlternativeAnalysisMeasureRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\DeleteAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\FindAlternativeAnalysisByIdRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAllAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAlternativeAnalysisStatusRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\GetAlternativeAnalysisDownloadRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\RunAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\UpdateAlternativeAnalysisRequest;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Transformers\AlternativeAnalysisTransformer;
use App\Containers\Koritsu\AlternativeAnalysis\Actions\StopAlternativeAnalysisByIdAction;
use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests\StopAlternativeAnalysisByIdRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Controllers\ApiController;
use Illuminate\Http\JsonResponse;

/**
 * Class Controller
 *
 * @package App\Containers\Koritsu\AlternativeAnalysis\UI\API\Controllers
 */
class Controller extends ApiController
{
    /**
     * @param CreateAlternativeAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function createAlternativeAnalysis(CreateAlternativeAnalysisRequest $request): array {

        $analysis = app(CreateAlternativeAnalysisAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param FindAlternativeAnalysisByIdRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function findAlternativeAnalysisById(FindAlternativeAnalysisByIdRequest $request): array {

        $analysis = app(FindAlternativeAnalysisByIdAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param GetAllAlternativeAnalysisRequest $request
     * @return array
     * @throws InvalidTransformerException
     */
    public function getAllAlternativeAnalyses(GetAllAlternativeAnalysisRequest $request): array {

        $analysis = app(GetAllAlternativeAnalysesAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }


    /**
     * @param GetAlternativeAnalysisStatusRequest $request
     * @return array
     * @throws NotFoundException
     */
    public function getStatus(GetAlternativeAnalysisStatusRequest $request): array {

        return app(GetAlternativeAnalysisStatusAction::class)->run($request);
    }

    /**
     * @throws NotFoundException
     */
    public function getDownload(GetAlternativeAnalysisDownloadRequest $request) {

        return app(GetAlternativeAnalysisDownloadAction::class)->run($request);
    }


    /**
     * @param StopAlternativeAnalysisByIdRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function stopAlternativeAnalysisById(StopAlternativeAnalysisByIdRequest $request): array {

        $analysis = app(StopAlternativeAnalysisByIdAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param DeleteAlternativeAnalysisRequest $request
     * @return JsonResponse
     * @throws NotFoundException
     */
    public function deleteAlternativeAnalysis(DeleteAlternativeAnalysisRequest $request): JsonResponse {

        app(DeleteAlternativeAnalysisAction::class)->run($request);
        return $this->noContent();
    }

    /**
     * @param UpdateAlternativeAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function updateAlternativeAnalysis(UpdateAlternativeAnalysisRequest $request): array {

        $project = app(UpdateAlternativeAnalysisAction::class)->run($request);
        return $this->transform($project, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param UpdateAlternativeAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function updateAlternativeAnalysisMeasures(UpdateAlternativeAnalysisRequest $request): array {

        $project = app(UpdateAlternativeAnalysisMeasuresAction::class)->run($request);
        return $this->transform($project, AlternativeAnalysisTransformer::class);
    }


    /**
     * @param RunAlternativeAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function runAlternativeAnalysisById(RunAlternativeAnalysisRequest $request): array {

        $analysis = app(RunAlternativeAnalysisAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param CopyAlternativeAnalysisRequest $request
     * @return array
     * @throws NotFoundException|InvalidTransformerException
     */
    public function copyAlternativeAnalysis(CopyAlternativeAnalysisRequest $request): array {

        $analysis = app(CopyAlternativeAnalysisAction::class)->run($request);
        return $this->transform($analysis, AlternativeAnalysisTransformer::class);
    }

    /**
     * @param DeleteAlternativeAnalysisMeasureRequest $request
     * @return JsonResponse
     * @throws NotFoundException
     */
    public function deleteAlternativeAnalysisMeasure(DeleteAlternativeAnalysisMeasureRequest $request): JsonResponse {

        app(DeleteAlternativeAnalysisMeasureAction::class)->run($request);
        return $this->noContent();
    }
}
