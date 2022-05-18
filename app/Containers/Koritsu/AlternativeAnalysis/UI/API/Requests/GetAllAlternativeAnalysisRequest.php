<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests;

use App\Ship\Parents\Requests\Request;

/**
 * Class GetAllUsersRequest.
 *
 * @property mixed $analysis_id
 */
class GetAllAlternativeAnalysisRequest extends Request
{

    /**
     * Define which Roles and/or Permissions has access to this request.
     *
     * @var  array
     */
    protected array $access = [
        'permissions' => 'list-analyses',
        'roles'       => 'admin',
    ];

    /**
     * Id's that needs decoding before applying the validation rules.
     *
     * @var  array
     */
    protected array $decode = [
        'project_id',
    ];

    /**
     * Defining the URL parameters (`/stores/999/items`) allows applying
     * validation rules on them and allows accessing them like request data.
     *
     * @var  array
     */
    protected array $urlParameters = [
        'project_id',
    ];

    /**
     * @return  array
     */
    public function rules(): array {
        return [
            'project_id' => 'required',
        ];
    }

    /**
     * @return  bool
     */
    public function authorize(): bool {
        return $this->check([
            'hasAccess',
        ]);
    }
}
