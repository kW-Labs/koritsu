<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\UI\API\Transformers;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Ship\Parents\Transformers\Transformer;

class AlternativeAnalysisTransformer extends Transformer
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

    ];

    /**
     * @param AlternativeAnalysis $alternative_analysis
     *
     * @return array
     */
    public function transform(AlternativeAnalysis $alternative_analysis):array
    {
        $response = [
            'object' => 'AlternativeAnalysis',
            'id' => $alternative_analysis->getHashedKey(),
            'name' =>$alternative_analysis->name,
            'data' => $alternative_analysis->data,
            'host' => $alternative_analysis->host,
            'analysis_id' => $alternative_analysis->getHashedKey('analysis_id'),
            'openstudio_analysis_id' => $alternative_analysis->openstudio_analysis_id,
            'ran_analysis' =>$alternative_analysis->ran_analysis,
            'status' => $alternative_analysis->status,
            'results' => $alternative_analysis->results,
            'user_id' => $alternative_analysis->getHashedKey('user_id'),
            'created_at' => $alternative_analysis->created_at,
            'updated_at' => $alternative_analysis->updated_at,

        ];

        return $this->ifAdmin([
            'real_id'    => $alternative_analysis->id,
        ], $response);
    }
}
