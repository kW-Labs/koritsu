<?php

namespace App\Containers\Koritsu\Project\Actions;

use App\Containers\Koritsu\Project\Tasks\FindProjectByIdTask;
use App\Containers\Koritsu\Project\Tasks\GetMeasureInfoTask;
use App\Containers\Koritsu\Project\UI\API\Requests\GetMeasureInfoRequest;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Actions\Action;

/**
 * Class GetMeasureInfoAction.
 *
 */
class GetMeasureInfoAction extends Action {

    /**
     * @param GetMeasureInfoRequest $request
     * @return mixed
     * @throws NotFoundException
     */
    public function run(GetMeasureInfoRequest $request) {

        $project =  app(FindProjectByIdTask::class)->run($request->id);
        if (!$project) {
            throw new NotFoundException();
        }

		# Check if Auth?

        return app(GetMeasureInfoTask::class)->run($request->id, $request->measure_name);
    }

}
