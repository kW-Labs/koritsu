<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Jobs;

use App\Containers\Koritsu\AlternativeAnalysis\Tasks\UpdateAlternativeAnalysisTask;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Jobs\Job;
use Artisan;
use stdClass;

/**
 * Class CreateOpenStudioBaselineJob
 */
class CreateAlternativeAnalysisJob extends Job {
    private object $alternative_analysis;

    public function __construct(object $alternative_analysis) {
        $this->alternative_analysis = $alternative_analysis;
    }

    /**
     * @throws InternalErrorException
     * @throws UpdateResourceFailedException
     * @throws NotFoundException
     */
    public function handle() {

        Artisan::call('openstudio:alternative', ['project_id' => $this->alternative_analysis->analysis->project_id, 'alternative_analysis_id' => $this->alternative_analysis->id]);
        $output = Artisan::output();
        $output_array = json_decode($output, true);

        $analysis_class = new stdClass();
        $analysis_class->analysis = new stdClass();
        $analysis_class->analysis->status = 'started';

        $analysis_class_failed = new stdClass();
        $analysis_class_failed->analysis = new stdClass();
        $analysis_class_failed->analysis->status = 'failed';

        $data = ['openstudio_analysis_id' => $output_array['analysis_id'] ?? '',
            'host' => $output_array['host'] ?? '',
            'results' => isset($output_array['results']) ? json_encode($output_array['results']) : '',
            'status' => isset($output_array['analysis_id']) ? json_encode($analysis_class) : json_encode($analysis_class_failed)
        ];

        app(UpdateAlternativeAnalysisTask::class)->run($data, $this->alternative_analysis);

        dispatch(new CheckAlternativeAnalysisStatusJob($this->alternative_analysis));
    }
}
