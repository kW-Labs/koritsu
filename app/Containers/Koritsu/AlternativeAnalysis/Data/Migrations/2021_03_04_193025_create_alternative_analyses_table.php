<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;

class CreateAlternativeAnalysesTable extends Migration
{

    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('alternative_analyses', function (Blueprint $table) {

            $table->id();
            $table->json('data')->nullable();
            $table->string('name')->nullable();
            $table->boolean('ran_analysis')->nullable();
            $table->string('host', 255)->nullable();
            $table->integer('analysis_id')->unsigned()->nullable();
            $table->foreign('analysis_id')->references('id')->on('analyses');
            $table->string('openstudio_analysis_id',255)->nullable();
            $table->json('status')->nullable();
            $table->json('results')->nullable();
            $table->integer('user_id')->unsigned();
            $table->foreign('user_id')->references('id')->on('users');
            $table->timestamps();

            // Index
            $table->index('analysis_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::dropIfExists('alternative_analyses');
    }
}
