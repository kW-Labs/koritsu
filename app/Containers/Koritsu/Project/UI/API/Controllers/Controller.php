<?php

namespace App\Containers\Koritsu\Project\UI\API\Controllers;

use App\Containers\Koritsu\Project\Actions\CreateProjectAction;
use App\Containers\Koritsu\Project\Actions\CreateProjectAndAnalysisAction;
use App\Containers\Koritsu\Project\Actions\DeleteProjectAction;
use App\Containers\Koritsu\Project\Actions\FindProjectByIdAction;
use App\Containers\Koritsu\Project\Actions\GetAllProjectsAction;
use App\Containers\Koritsu\Project\Actions\GetMeasureInfoAction;
use App\Containers\Koritsu\Project\Actions\UpdateProjectAction;
use App\Containers\Koritsu\Project\UI\API\Requests\CreateProjectRequest;
use App\Containers\Koritsu\Project\UI\API\Requests\DeleteProjectRequest;
use App\Containers\Koritsu\Project\UI\API\Requests\FindProjectByIdRequest;
use App\Containers\Koritsu\Project\UI\API\Requests\GetAllProjectRequest;
use App\Containers\Koritsu\Project\UI\API\Requests\GetMeasureInfoRequest;
use App\Containers\Koritsu\Project\UI\API\Requests\UpdateProjectRequest;
use App\Containers\Koritsu\Project\UI\API\Transformers\ProjectTransformer;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Controllers\ApiController;
use Illuminate\Http\JsonResponse;
use Apiato\Core\Exceptions\InvalidTransformerException;

/**
 * Class Controller
 *
 * @package App\Containers\Koritsu\Project\UI\API\Controllers
 */
class Controller extends ApiController {

    /**
     * @param CreateProjectRequest $request
     * @return array
     * @throws InvalidTransformerException
     */
    public function createProject(CreateProjectRequest $request): array {

        $project = app(CreateProjectAction::class)->run($request);
        return $this->transform($project, ProjectTransformer::class);
    }

    /**
     * @throws InvalidTransformerException
     */
    public function createProjectAndAnalysis(CreateProjectRequest $request): array {

        $project = app(CreateProjectAndAnalysisAction::class)->run($request);
        return $this->transform($project, ProjectTransformer::class);
    }

    /**
     * @param FindProjectByIdRequest $request
     * @return array
     * @throws NotFoundException
     * @throws InvalidTransformerException
     */
    public function findProjectById(FindProjectByIdRequest $request): array {
        $project = app(FindProjectByIdAction::class)->run($request);
        return $this->transform($project, ProjectTransformer::class);
    }

    /**
     * @param GetAllProjectRequest $request
     * @return array
     * @throws InvalidTransformerException
     */
    public function getAllProjects(GetAllProjectRequest $request): array {

        $project = app(GetAllProjectsAction::class)->run($request);
        return $this->transform($project, ProjectTransformer::class);
    }

    /**
     * @param UpdateProjectRequest $request
     * @return array
     * @throws InvalidTransformerException
     * @throws NotFoundException
     */
    public function updateProject(UpdateProjectRequest $request): array {

        $project = app(UpdateProjectAction::class)->run($request);
        return $this->transform($project, ProjectTransformer::class);
    }


    /**
     * @param DeleteProjectRequest $request
     * @throws NotFoundException
     * @return JsonResponse
     */
    public function deleteProject(DeleteProjectRequest $request): JsonResponse {

        app(DeleteProjectAction::class)->run($request);
        return $this->noContent();
    }

    // TODO: Validate / check json response

    /**
     * @throws NotFoundException
     */
    public function getMeasureInfo(GetMeasureInfoRequest $request): string {
        return app(GetMeasureInfoAction::class)->run($request);
    }

}
