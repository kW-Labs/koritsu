<?php

namespace App\Containers\Koritsu\Analysis\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 */
class ProjectIdAndUserIdCriteria extends Criteria {

    /**
     * @var string
     */
    private string $projectId;
    private string $userId;

    /**
     * UserIdCriteria constructor.
     *
     * @param $projectId
     * @param $userId
     */
    public function __construct($projectId, $userId) {
        $this->projectId = $projectId;
        $this->userId = $userId;
    }


    /**
     * @param                            $model
     * @param PrettusRepositoryInterface $repository
     *
     * @return mixed
     */
    public function apply($model, PrettusRepositoryInterface $repository) {
        return $model->where('project_id', '=', $this->projectId)->where('user_id', '=', $this->userId);
    }
}
