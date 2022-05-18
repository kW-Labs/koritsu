<?php

namespace App\Containers\Koritsu\Project\Tasks;

use App\Containers\Koritsu\Project\Data\Repositories\ProjectRepository;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Support\Facades\Artisan;

/**
 * Class GetMeasureInfoTask.
 *
 */
class GetMeasureInfoTask extends Task
{

    /**
     * @var  ProjectRepository
     */
    protected ProjectRepository $repository;

    /**
     * GetAllProjectsTask constructor.
     *
     * @param ProjectRepository $repository
     */
    public function __construct(ProjectRepository $repository)
    {
        $this->repository = $repository;
    }

    public function run($project_id, $measure_name): string {
        Artisan::call('openstudio:measure_info', ['project_id' => $project_id, 'measure_name' => $measure_name]);
        return Artisan::output();
    }


}
