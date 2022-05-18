<?php

namespace App\Containers\Koritsu\Analysis\UI\API\Transformers;

use App\Containers\Koritsu\AlternativeAnalysis\UI\API\Transformers\AlternativeAnalysisTransformer;
use App\Containers\Koritsu\Analysis\Models\Analysis;
use App\Ship\Parents\Transformers\Transformer;
use League\Fractal\Resource\Collection;

class AnalysisTransformer extends Transformer
{
    /**
     * @var  array
     */
    protected array $defaultIncludes = [
        'alternativeAnalysis'
    ];

    /**
     * @var  array
     */
    protected array $availableIncludes = [
    ];

    /**
     * @param Analysis $analysis
     *
     * @return array
     */
    public function transform(Analysis $analysis): array
    {
        $response = [
            'object' => $analysis->getResourceKey(),
            'id' => $analysis->getHashedKey(),
            'data' => $analysis->data,
            'host' => $analysis->host,
            'results' => $analysis->results,
            'ran_analysis' =>$analysis->ran_analysis,
            'openstudio_analysis_id' => $analysis->openstudio_analysis_id,
            'status' => $analysis->status,
            'project_id' => $analysis->getHashedKey('project_id'),
            'user_id' => $analysis->getHashedKey('user_id'),
            'created_at' => $analysis->created_at,
            'updated_at' => $analysis->updated_at,
            'readable_created_at' => $analysis->created_at->diffForHumans(),
            'readable_updated_at' => $analysis->updated_at->diffForHumans(),
        ];

        return $this->ifAdmin([
            'real_id' => $analysis->id,
        ], $response);
    }

    public function includeAlternativeAnalysis(Analysis $analysis): Collection
    {
        return $this->collection($analysis->alternativeAnalysis, new AlternativeAnalysisTransformer());
    }
}
