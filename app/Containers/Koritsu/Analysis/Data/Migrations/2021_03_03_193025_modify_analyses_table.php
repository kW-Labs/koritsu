<?php

use Illuminate\Database\Migrations\Migration;

class ModifyAnalysesTable extends Migration {

    /**
     * Run the migrations.
     */
    public function up() {
        Schema::table('analyses', function ($table)
        {
            $table->foreign('project_id')->references('id')->on('projects');
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down() {
    }
}
