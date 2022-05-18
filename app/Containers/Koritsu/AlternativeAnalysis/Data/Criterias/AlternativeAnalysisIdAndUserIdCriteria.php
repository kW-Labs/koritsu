<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 */
class AlternativeAnalysisIdAndUserIdCriteria extends Criteria {

    /**
     * @var string
     */
    private string $analysisId;
    private string $userId;

    /**
     * UserIdCriteria constructor.
     *
     * @param $analysisId
     * @param $userId
     */
    public function __construct($analysisId, $userId) {
        $this->analysisId = $analysisId;
        $this->userId = $userId;
    }


    /**
     * @param                            $model
     * @param PrettusRepositoryInterface $repository
     *
     * @return mixed
     */
    public function apply($model, PrettusRepositoryInterface $repository) {
        return $model->where('analysis_id', '=', $this->analysisId)->where('user_id', '=', $this->userId);
    }
}
