<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Models;

use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Ship\Parents\Models\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @method static where(string $string, $id)
 * @property mixed $name
 * @property mixed $data
 * @property mixed $host
 * @property mixed $openstudio_analysis_id
 * @property mixed $ran_analysis
 * @property mixed $status
 * @property mixed $results
 * @property mixed $created_at
 * @property mixed $updated_at
 * @property mixed $id
 * @property mixed $user_id
 */
class AlternativeAnalysis extends Model {
    protected $fillable = [
        'name',
        'data',
        'host',
        'analysis_id',
        'type_id',
        'status',
        'measures',
        'openstudio_analysis_id',
        'results',
        'ran_analysis',
        'user_id',
    ];


    public function analysis(): BelongsTo {
        return $this->belongsTo(Analysis::class);
    }

    protected $attributes = [

    ];

    protected $hidden = [

    ];

    protected $casts = [
        'user_id' => 'integer',
        'analysis_id' => 'integer',
        'ran_analysis' => 'boolean',
        'data' => 'array',
    ];

    protected $dates = [
        'created_at',
        'updated_at',
    ];

    /**
     * A resource key to be used by the the JSON API Serializer responses.
     */
    protected string $resourceKey = 'analyses';
}
