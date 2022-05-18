<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Jobs\CreateAlternativeAnalysisJob;
use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories\AlternativeAnalysisRepository;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Class CreateAlternativeAnalysisByCredentialsTask.
 *
 */
class RunAlternativeAnalysisTask extends Task {

    /**
     * @param $alternative_analysis
     * @return  mixed
     * @throws \Apiato\Core\Abstracts\Exceptions\Exception
     * @throws CreateResourceFailedException
     */
    public function run($alternative_analysis):AlternativeAnalysis {

        try {
            dispatch(new CreateAlternativeAnalysisJob($alternative_analysis));
        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        try {
            $alternative_analysis = $this->repository->update(['ran_analysis' => true], $alternative_analysis->id);
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException('Alternative Analysis Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $alternative_analysis;
    }


    protected AlternativeAnalysisRepository $repository;

    public function __construct(AlternativeAnalysisRepository $repository) {
        $this->repository = $repository;
    }

}
