<?php

namespace App\Containers\Koritsu\Project\UI\API\Requests;

use App\Ship\Parents\Requests\Request;

/**
 * Class GetAllUsersRequest.
 *
 */
class GetAllProjectRequest extends Request
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

    ];

    /**
     * Defining the URL parameters (`/stores/999/items`) allows applying
     * validation rules on them and allows accessing them like request data.
     *
     * @var  array
     */
    protected array $urlParameters = [

    ];

    /**
     * @return  array
     */
    public function rules(): array {
        return [

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
