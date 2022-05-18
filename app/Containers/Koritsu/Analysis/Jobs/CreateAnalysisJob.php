<?php

namespace App\Containers\Koritsu\Analysis\Jobs;

use App\Containers\Koritsu\Analysis\Tasks\UpdateAnalysisTask;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Jobs\Job;
use Artisan;
use stdClass;

/**
 * Class CreateOpenStudioBaselineJob
 */
class CreateAnalysisJob extends Job {
    private object $analysis;

    public function __construct(object $analysis) {
        $this->analysis = $analysis;
    }

    public function handle() {

        try{
            Artisan::call('openstudio:base', ['project_id' => $this->analysis->project_id]);
            $output = Artisan::output();
            $output_array = json_decode($output, true);

            $analysis_class = new stdClass();
            $analysis_class->analysis = new stdClass();
            $analysis_class->analysis->status = 'started';

            $analysis_class_failed = new stdClass();
            $analysis_class_failed->analysis = new stdClass();
            $analysis_class_failed->analysis->status = 'failed';

            $data = [
                'openstudio_analysis_id' => $output_array['analysis_id'] ?? '',
                'ran_analysis' => isset($output_array['analysis_id']),
                'data' => isset($output_array['data']) ? json_encode($output_array['data']) : json_encode([]),
                'results' => isset($output_array['results']) ? json_encode($output_array['results']) : '',
                'status' => isset($output_array['analysis_id']) ? json_encode($analysis_class) : json_encode($analysis_class_failed),
            ];

            app(UpdateAnalysisTask::class)->run($data, $this->analysis->id);
            dispatch(new CheckAnalysisStatusJob($this->analysis));

        } catch (InternalErrorException|NotFoundException|UpdateResourceFailedException $e) {

        }

    }
}
