<?php

namespace App\Containers\Koritsu\Project\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 * @author  Mahmoud Zalt <mahmoud@zalt.me>
 */
class UserIdCriteria extends Criteria {

    /**
     * @var string
     */
    private string $userId;

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
