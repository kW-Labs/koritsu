<?php

namespace App\Containers\Koritsu\Analysis\Jobs;

use Apiato\Core\Abstracts\Exceptions\Exception;
use App\Containers\Koritsu\Analysis\Tasks\CreateAnalysisByCredentialsTask;
use App\Containers\Koritsu\Project\Tasks\UpdateProjectTask;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Jobs\Job;

/**
 * Class CreateOpenStudioBaselineJob
 */
class CreateOpenStudioBaselineJob extends Job {
    private object $project;

    public function __construct(object $project) {
        $this->project = $project;
    }

    /**
     * @throws InternalErrorException
     * @throws NotFoundException
     * @throws UpdateResourceFailedException
     * @throws CreateResourceFailedException
     * @throws Exception
     */
    public function handle() {

        $analysis =  app(CreateAnalysisByCredentialsTask::class)->run(
            $this->project->user_id,
            $this->project->id,
        );

        $data = ['analysis_id' => $analysis->id];
        app(UpdateProjectTask::class)->run($data, $this->project->id);

        dispatch(new CheckAnalysisStatusJob($analysis));
    }
}
