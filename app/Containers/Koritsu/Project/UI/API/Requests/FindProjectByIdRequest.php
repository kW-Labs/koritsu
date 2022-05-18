<?php

namespace App\Containers\Koritsu\Project\UI\API\Requests;

use App\Ship\Parents\Requests\Request;
use App\Containers\Koritsu\Project\Traits\IsOwnerTrait;

/**
 * Class FindProjectByIdRequest.
 *
 * @property mixed $id
 */
class FindProjectByIdRequest extends Request {

    use IsOwnerTrait;

    /**
     * Define which Roles and/or Permissions has access to this request.
     *
     * @var  array
     */
    protected array $access = [
        'permissions' => 'search-projects',
        'roles' => '',
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

    public function rules(): array
    {
        return [
            'id' => 'required|exists:projects,id'
        ];
    }

    public function authorize(): bool {
        return $this->check([
            'hasAccess|isOwner',
        ]);
    }
}
