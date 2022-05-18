<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 */
class UserIdCriteria extends Criteria {

    /**
     * @var string
     */
    private $userId;

    /**
     * UserIdCriteria constructor.
     *
     * @param $userId
     */
    public function __construct($userId) {
        $this->userId = $userId;
    }


    /**
     * @param                            $model
     * @param PrettusRepositoryInterface $repository
     *
     * @return mixed
     */
    public function apply($model, PrettusRepositoryInterface $repository) {
        return $model->where('user_id', '=', $this->userId);
    }
}
