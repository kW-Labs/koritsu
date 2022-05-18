<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Data\Repositories;

use App\Ship\Parents\Repositories\Repository;

/**
 * Class AlternativeAnalysisRepository
 */
class AlternativeAnalysisRepository extends Repository {

    /**
     * @var array
     */
    protected $fieldSearchable = [
        'name' => 'like',
        'id' => '=',
        'user_id' => '=',
        'analysis_id' => '=',
        'openstudio_analysis_id' => '=',
        'created_at' => 'like',
    ];

}
