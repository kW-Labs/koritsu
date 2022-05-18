<?php

namespace App\Containers\Koritsu\Project\Data\Seeders;

use App\Containers\AppSection\Authorization\Tasks\CreatePermissionTask;
use App\Containers\AppSection\Authorization\Tasks\CreateRoleTask;
use App\Ship\Exceptions\CreateResourceFailedException;
use App\Ship\Parents\Seeders\Seeder;

/**
 * Class ProjectPermissionsSeeder_1
 *
 */
class ProjectPermissionsSeeder_1 extends Seeder {
    /**
     * Run the database seeds.
     *
     * @return void
     * @throws CreateResourceFailedException
     */
    public function run() {
        // Default Permissions ----------------------------------------------------------
        $role = app(CreateRoleTask::class)->run('general', 'General', 'General User Role', 777);

        $permissions = [];
        $permissions[] = app(CreatePermissionTask::class)->run('create-projects', 'Create a Project');
        $permissions[] = app(CreatePermissionTask::class)->run('search-projects', 'Find a Project in the DB.');
        $permissions[] = app(CreatePermissionTask::class)->run('list-projects', 'Get All Projects.');
        $permissions[] = app(CreatePermissionTask::class)->run('update-projects', 'Update a Project.');
        $permissions[] = app(CreatePermissionTask::class)->run('delete-projects', 'Delete a Project.');
        $permissions[] = app(CreatePermissionTask::class)->run('refresh-projects', 'Refresh Project data.');
        $permissions[] = app(CreatePermissionTask::class)->run('create-analyses', 'Create a Analysis');
        $permissions[] = app(CreatePermissionTask::class)->run('search-analyses', 'Find a Analysis in the DB.');
        $permissions[] = app(CreatePermissionTask::class)->run('list-analyses', 'Get All Analyses.');
        $permissions[] = app(CreatePermissionTask::class)->run('update-analyses', 'Update a Analysis.');
        $permissions[] = app(CreatePermissionTask::class)->run('delete-analyses', 'Delete a Analysis.');
        $permissions[] = app(CreatePermissionTask::class)->run('refresh-analyses', 'Refresh Analysis data.');

        $role->syncPermissions($permissions);

    }
}
