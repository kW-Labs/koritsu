<?php

namespace App\Containers\Koritsu\Analysis\Data\Criterias;

use App\Ship\Parents\Criterias\Criteria;
use Prettus\Repository\Contracts\RepositoryInterface as PrettusRepositoryInterface;

/**
 * Class ClientsCriteria.
 *
 */
class ProjectIdCriteria extends Criteria {

    /**
     * @var string
     */
    private string $projectId;

    /**
     * UserIdCriteria constructor.
     *
     * @param $projectId
     */
    public function __construct($projectId) {
        $this->projectId = $projectId;
    }


    /**
     * @param                            $model
     * @param PrettusRepositoryInterface $repository
     *
     * @return mixed
     */
    public function apply($model, PrettusRepositoryInterface $repository) {
        return $model->where('project_id', '=', $this->projectId);
    }
}
