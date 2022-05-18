<?php

namespace App\Containers\Koritsu\Analysis\UI\API\Requests;

use App\Ship\Parents\Requests\Request;

/**
 * Class StopAnalysisByIdRequest.
 *
 * @property mixed $id
 */
class StopAnalysisByIdRequest extends Request
{

    /**
     * Define which Roles and/or Permissions has access to this request.
     *
     * @var  array
     */
    protected array $access = [
        'permissions' => 'search-analyses',
        'roles'       => '',
    ];

    /**
     * Id's that needs decoding before applying the validation rules.
     *
     * @var  array
     */
    protected array $decode = [
        'id',
    ];

    /**
     * Defining the URL parameters (`/stores/999/items`) allows applying
     * validation rules on them and allows accessing them like request data.
     *
     * @var  array
     */
    protected array $urlParameters = [
        'id',
    ];

    /**
     * @return  array
     */
    public function rules(): array {
        return [
            'id' => 'required|exists:analyses,id',
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
