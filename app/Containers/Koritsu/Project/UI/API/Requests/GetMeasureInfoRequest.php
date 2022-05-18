<?php

namespace App\Containers\Koritsu\Project\UI\API\Requests;

use App\Ship\Parents\Requests\Request;

/**
 * Class GetMeasureInfoRequest.
 *
 * @property mixed $measure_name
 * @property mixed $id
 */
class GetMeasureInfoRequest extends Request
{

    /**
     * Define which Roles and/or Permissions has access to this request.
     *
     * @var  array
     */
    protected array $access = [
        'permissions' => 'list-projects',
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
        'measure_name'
    ];

    /**
     * @return  array
     */
    public function rules(): array {
        return [
            'id' => 'required|exists:projects,id',
            'measure_name' => 'required',
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
