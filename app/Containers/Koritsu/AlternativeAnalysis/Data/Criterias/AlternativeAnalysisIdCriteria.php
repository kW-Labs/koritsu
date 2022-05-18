<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 */
class AlternativeAnalysisIdCriteria extends Criteria {

    /**
     * @var string
     */
    private string $analysisId;

    /**
     * UserIdCriteria constructor.
     *
     * @param $analysisId
     */
    public function __construct($analysisId) {
        $this->analysisId = $analysisId;
    }


    /**
     * @param                            $model
     * @param PrettusRepositoryInterface $repository
     *
     * @return mixed
     */
    public function apply($model, PrettusRepositoryInterface $repository) {
        return $model->where('analysis_id', '=', $this->analysisId);
    }
}
