<?php

namespace App\Containers\Koritsu\Project\Data\Repositories;

use App\Ship\Parents\Repositories\Repository;

/**
 * Class ProjectRepository
 */
class ProjectRepository extends Repository
{

    /**
     * @var array
     */
    protected $fieldSearchable = [
        'name'       => 'like',
        'id'         => '=',
        'created_at' => 'like',
    ];

}
