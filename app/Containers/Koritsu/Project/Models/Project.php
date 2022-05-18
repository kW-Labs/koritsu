<?php

namespace App\Containers\Koritsu\Project\Models;

use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Containers\AppSection\User\Models\User;
use App\Ship\Parents\Models\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * @property mixed $analysis
 * @property mixed $id
 * @property mixed $analysis_id
 * @property mixed $data
 * @property mixed $created_at
 * @property mixed $updated_at
 * @property mixed $user_id
 * @method static findOrFail(array|string|null $project_id)
 */
class Project extends Model {

    protected $fillable = [
        'data', 'user_id', 'analysis_id'
    ];

    public function user(): BelongsTo {
        return $this->belongsTo(User::class);
    }

    public function analysis(): HasOne {
        return $this->hasOne(Analysis::class,'id', 'analysis_id');
    }

    protected $attributes = [

    ];

    protected $hidden = [

    ];

    protected $casts = [
        'user_id' => 'integer',
    ];

    protected $dates = [
        'created_at',
        'updated_at',
    ];

    /**
     * A resource key to be used by the JSON API Serializer responses.
     */
    protected string $resourceKey = 'projects';
}
