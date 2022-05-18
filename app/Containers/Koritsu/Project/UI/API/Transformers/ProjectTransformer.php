<?php

namespace App\Containers\Koritsu\Project\UI\API\Transformers;

use App\Containers\Koritsu\Analysis\UI\API\Transformers\AnalysisTransformer;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Parents\Transformers\Transformer;

class ProjectTransformer extends Transformer
{
    /**
     * @var  array
     */
    protected array $defaultIncludes = [
    ];

    /**
     * @var  array
     */
    protected array $availableIncludes = [
        'analysis'
    ];

    /**
     * @param Project $project
     *
     * @return array
     */
    public function transform(Project $project): array
    {
        $response = [
            'object' => $project->getResourceKey(),
            'id' => $project->getHashedKey(),
            'data' => $project->data,
            'analysis_id' => $project->analysis_id,
            'user_id' => $project->getHashedKey('user_id'),
            'created_at' => $project->created_at,
            'updated_at' => $project->updated_at,
        ];

        return $this->ifAdmin([
            'real_id'    => $project->id,
        ], $response);
    }

    public function includeAnalysis(Project $project)
    {
        if($project->analysis) {
            return $this->item($project->analysis, new AnalysisTransformer());
        }

    }

}
