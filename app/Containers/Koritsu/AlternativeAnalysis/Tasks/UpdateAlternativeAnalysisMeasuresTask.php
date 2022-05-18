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
 * Class UpdateAlternativeAnalysisTask.
 *
 */
class UpdateAlternativeAnalysisMeasuresTask extends Task {

    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

    /**
     * @param $measure
     * @param $alternative_analysis
     *
     * @return mixed
     * @throws InternalErrorException
     * @throws NotFoundException
     * @throws UpdateResourceFailedException
     */
    public function run($measure, $alternative_analysis): AlternativeAnalysis {
        if (empty($measure)) {
            throw new UpdateResourceFailedException('Inputs are empty.');
        }

        try {

            // Get Current Measures from Alternatives
            $name = strtolower($measure['data']['measure_name'] ?? ($measure['data']['name'] ?? ''));
            $measure_obj = $alternative_analysis->data ?? [];
            $measure_names = [];

            if (!empty($measure_obj['measures'])) {
                foreach ($measure_obj['measures'] as $current_measure) {
                    if (isset($current_measure['measure_name'])) {
                        $measure_names[] = strtolower($current_measure['measure_name']);
                    } else {
                        if (isset($current_measure['name'])) {
                            $measure_names[] = strtolower($current_measure['name']);
                        }
                    }
                }
            } else {
                $measure_obj['measures'] = [];
            }

            // Verify Measure Name is not already added
            // Else Overwrite
            if (!in_array(strtolower($name), $measure_names)) {
                $measure_obj['measures'][] = $measure['data'];
            } else {

                if (!empty($measure_obj['measures'])) {
                    foreach ($measure_obj['measures'] as $index => $current_measure) {

                        if (strpos(strtolower($current_measure['measure_name']), $name) !== false) {
                            $measure_obj['measures'][$index] = $measure['data'];
                            break;
                        }
                    }
                }
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
