<?php

namespace App\Containers\Koritsu\Analysis\Models;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Parents\Models\Model;

/**
 * @property mixed $id
 * @property mixed $user_id
 * @property mixed $data
 * @property mixed $host
 * @property mixed $results
 * @property mixed $ran_analysis
 * @property mixed $openstudio_analysis_id
 * @property mixed $status
 * @property mixed $created_at
 * @property mixed $updated_at
 * @property mixed $alternativeAnalysis
 */
class Analysis extends Model {
    protected $fillable = [
        'name',
        'data',
        'host',
        'ran_analysis',
        'project_id',
        'type_id',
        'status',
        'openstudio_analysis_id',
        'results',
        'user_id',
    ];


    public function project() {
        return $this->belongsTo(Project::class);
    }

    public function alternativeAnalysis() {
        return $this->hasMany(AlternativeAnalysis::class,'analysis_id','id');
    }

    protected $attributes = [

    ];

    protected $hidden = [

    ];

    protected $casts = [
        'user_id' => 'integer',
        'project_id' => 'integer',
    ];

    protected $dates = [
        'created_at',
        'updated_at',
    ];

    /**
     * A resource key to be used by the the JSON API Serializer responses.
     */
    protected $resourceKey = 'analyses';
}
