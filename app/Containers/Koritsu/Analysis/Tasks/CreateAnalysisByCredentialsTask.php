<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Support\Facades\Artisan;
use stdClass;

/**
 * Class CreateAnalysisByCredentialsTask.
 *
 */
class CreateAnalysisByCredentialsTask extends Task {

    /**
     * @param integer $user_id
     * @param integer $project_id
     *
     * @return  mixed
     * @throws CreateResourceFailedException
     * @throws \Apiato\Core\Abstracts\Exceptions\Exception
     */
    public function run(
        int $user_id,
        int $project_id
    ): Analysis {

        // TODO: Log Error
        try {

            // TODO: Catch blank response
            Artisan::call('openstudio:base', ['project_id' => $project_id]);
            $output = Artisan::output();
            $output_array = json_decode($output, true);

            $analysis_class = new stdClass();
            $analysis_class->analysis = new stdClass();
            $analysis_class->analysis->status = 'started';

            $analysis_class_failed = new stdClass();
            $analysis_class_failed->analysis = new stdClass();
            $analysis_class_failed->analysis->status = 'failed';

            $analysis = $this->repository->create([
                'user_id' => $user_id,
                'openstudio_analysis_id' => $output_array['analysis_id'] ?? '',
                'ran_analysis' => isset($output_array['analysis_id']),
                'host' => $output_array['host'] ?? '',
                'data' => isset($output_array['data']) ? json_encode($output_array['data']) : json_encode([]),
                'results' => isset($output_array['results']) ? json_encode($output_array['results']) : '',
                'status' => isset($output_array['analysis_id']) ? json_encode($analysis_class) : json_encode($analysis_class_failed),
                'project_id' => $project_id,
            ]);

        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        return $analysis;
    }

    protected AnalysisRepository $repository;

    public function __construct(AnalysisRepository $repository) {
        $this->repository = $repository;
    }

}
