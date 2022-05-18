<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\AppSection\Authentication\Tasks\GetAuthenticatedUserTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\GetAllAlternativeAnalysesTask;
use App\Containers\Koritsu\AlternativeAnalysis\Tasks\UpdateAlternativeAnalysisTask;
use App\Containers\Koritsu\Analysis\Tasks\UpdateAnalysisTask;
use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Class UpdateProjectTask.
 *
 */
class UpdateProjectTask extends Task
{

    protected ProjectRepository $repository;

    public function __construct(ProjectRepository $repository)
    {
        $this->repository = $repository;
    }

    /**
     * @param $projectData
     * @param $projectId
     * @param bool $rerun
     * @return mixed
     * @throws InternalErrorException
     * @throws NotFoundException
     * @throws UpdateResourceFailedException
     */
    public function run($projectData, $projectId, bool $rerun = False): Project
    {
        if (empty($projectData)) {
            throw new UpdateResourceFailedException('Inputs are empty.');
        }

        try {
            $project = $this->repository->update($projectData, $projectId);

            if($rerun) {
                // Update Analysis
                $analysis_id = $project["analysis_id"];
                app(UpdateAnalysisTask::class)->run(["ran_analysis" => false, 'data' => null, 'openstudio_analysis_id' => null, 'results' => null, 'status'=>null], $analysis_id);

                // Update Alternatives
                $user =  app(GetAuthenticatedUserTask::class)->run();
                $alternative_analyses = app(GetAllAlternativeAnalysesTask::class)->run($user, $analysis_id);
                foreach ($alternative_analyses as $alternative_analysis){
                    app(UpdateAlternativeAnalysisTask::class)->run(["ran_analysis" => false, 'openstudio_analysis_id' => null, 'results' => null, 'status'=>null], $alternative_analysis);
                }
            }
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException('Project Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $project;
    }

}
