<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\UI\API\Requests;

use App\Containers\Koritsu\AlternativeAnalysis\Traits\IsOwnerTrait;
use App\Ship\Parents\Requests\Request;

/**
 * Class UpdateProjectRequest.
 *
 * @property mixed $id
 */
class UpdateAlternativeAnalysisRequest extends Request {

    use IsOwnerTrait;

    /**
     * Define which Roles and/or Permissions has access to this request.
     *
     * @var  array
     */
    protected array $access = [
        'permissions' => 'update-projects',
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
        // is this an admin who has access to permission `update-projects`
        // or the user is updating his own object (is the owner).
        return $this->check([
            'hasAccess|isOwner',
        ]);
    }
}
