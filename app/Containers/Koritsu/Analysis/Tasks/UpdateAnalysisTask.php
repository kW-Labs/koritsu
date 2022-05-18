<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Exceptions\UpdateResourceFailedException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Class UpdateAnalysisTask.
 *
 */
class UpdateAnalysisTask extends Task {

    protected AnalysisRepository $repository;

    public function __construct(AnalysisRepository $repository) {
        $this->repository = $repository;
    }

    /**
     * @param $analysisData
     * @param $analysisId
     *
     * @return mixed
     * @return  Analysis
     * @throws NotFoundException
     * @throws UpdateResourceFailedException
     *
     * @throws InternalErrorException
     */
    public function run($analysisData, $analysisId): Analysis {
        if (empty($analysisData)) {
            throw new UpdateResourceFailedException('Inputs are empty.');
        }

        try {
            $analysis = $this->repository->update($analysisData, $analysisId);
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException('Analysis Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $analysis;
    }

}
