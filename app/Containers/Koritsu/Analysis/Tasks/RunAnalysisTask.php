<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\Analysis\Jobs\CreateAnalysisJob;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Exceptions\InternalErrorException;
use App\Ship\Exceptions\NotFoundException;
use App\Ship\Parents\Tasks\Task;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Class CreateAnalysisByCredentialsTask.
 *
 */
class RunAnalysisTask extends Task {

    /**
     * @param $analysis
     * @return  mixed
     * @throws NotFoundException
     * @throws InternalErrorException
     * @throws CreateResourceFailedException|\Apiato\Core\Abstracts\Exceptions\Exception
     */
    public function run($analysis):Analysis {

        try {
            dispatch(new CreateAnalysisJob($analysis));
        } catch (Exception $e) {
            throw (new CreateResourceFailedException())->debug($e);
        }

        try {
            $analysis = $this->repository->update(['ran_analysis' => true], $analysis->id);
        } catch (ModelNotFoundException $exception) {
            throw new NotFoundException(' Analysis Not Found.');
        } catch (Exception $exception) {
            throw new InternalErrorException();
        }

        return $analysis;
    }


    protected AnalysisRepository $repository;

    public function __construct(AnalysisRepository $repository) {
        $this->repository = $repository;
    }

}
