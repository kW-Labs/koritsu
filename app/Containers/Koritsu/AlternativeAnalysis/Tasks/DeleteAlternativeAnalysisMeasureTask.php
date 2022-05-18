<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Class DeleteAlternativeAnalysisMeasureTask.
 *
 */
class DeleteAlternativeAnalysisMeasureTask extends Task {

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

    /**
     * @param $data
     * @param $alternative_analysis
     *
     * @return mixed
     * @return AlternativeAnalysis
     * @throws NotFoundException
     * @throws UpdateResourceFailedException
     *
     * @throws InternalErrorException
     */
    public function run($data, $alternative_analysis): AlternativeAnalysis {
        if (empty($data)) {
            throw new UpdateResourceFailedException('Measure Name is empty.');
        }

        try {

            // Remove measure matching the measure_name
            $measure_obj = $alternative_analysis->data ?? [];
            $deleted_masure = false;
            if (!empty($measure_obj['measures'])) {
                foreach ($measure_obj['measures'] as $index => $current_measure) {

                    if (strpos($current_measure['measure_name'], $data['name']) !== false) {
                        unset($measure_obj['measures'][$index]);
                        $deleted_masure = true;
                        break;
                    }
                }
            }

            if ($deleted_masure) {
                sort($measure_obj['measures']);
            }

            $data = ['data' => $measure_obj, 'ran_analysis' => false, 'status' => null, 'results' => null, 'openstudio_analysis_id' => null];
            $alternative_analysis = $this->repository->update($data, $alternative_analysis->id);
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException('AlternativeAnalysis Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $alternative_analysis;
    }

}
