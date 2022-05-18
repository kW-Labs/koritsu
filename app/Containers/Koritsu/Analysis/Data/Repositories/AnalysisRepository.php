<?php

namespace App\Containers\Koritsu\Analysis\Data\Repositories;

use App\Ship\Parents\Repositories\Repository;

/**
 * Class AnalysisRepository
 */
class AnalysisRepository extends Repository {

    /**
     * @var array
     */
    protected $fieldSearchable = [
        'id' => '=',
        'user_id' => '=',
        'project_id' => '=',
        'openstudio_analysis_id' => '=',
        'created_at' => 'like',
    ];

}
