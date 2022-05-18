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
class UpdateAlternativeAnalysisTask extends Task {

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
            throw new UpdateResourceFailedException('Inputs are empty.');
        }

        try {
            $alternative_analysis = $this->repository->update($data, $alternative_analysis->id);
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException('Alternative Analysis Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $alternative_analysis;
    }

}
