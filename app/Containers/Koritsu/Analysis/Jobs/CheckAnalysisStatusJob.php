<?php

namespace App\Containers\Koritsu\Analysis\Jobs;

use App\Containers\Koritsu\Analysis\Tasks\GetAnalysisStatusTask;
use App\Ship\Parents\Jobs\Job;
use Illuminate\Support\Facades\Storage;

/**
 * Class CheckAnalysisStatusJob
 */
 class CheckAnalysisStatusJob extends Job
 {
     private object $analysis;
     public function __construct(object $analysis) {
         $this->analysis = $analysis;
     }

     public function handle() {

         // TODO: Check and Stop this if running for days?
         $status =  app(GetAnalysisStatusTask::class)->run($this->analysis);
         if(isset($status['status']['analysis']['status'])){
            if($status['status']['analysis']['status'] !== 'completed') {
                sleep(20);
                dispatch(new CheckAnalysisStatusJob($this->analysis));
            }else{
                
                // TODO: Make a shared TASK
                // TODO: Check if we downloaded in.osm
                // TODO: Check if status exists first
                sleep(15); // Add a minor delay just in case file is not ready
                $data_point_id = $status['status']['analysis']['data_points'][0]['id'];
                $data_point_status= $status['status']['analysis']['data_points'][0]['status_message'];
                if($data_point_status === 'completed normal') {
                    $url = "http://" . $this->analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=in.osm";
                    $contents = file_get_contents($url);
                    $path = 'projects/' . $this->analysis->project_id .'/Base/results/in.osm';
                    Storage::disk('local')->put($path , $contents);

                    $url = "http://" . $this->analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=data_point.zip";
                    $contents = file_get_contents($url);
                    $zip_path = 'projects/' . $this->analysis->project_id .'/downloads/' . $data_point_id . '.zip';
                    Storage::disk('local')->put($zip_path , $contents);

                    $url = "http://" . $this->analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=koritsu_run_report_report.json";
                    $contents = file_get_contents($url);
                    $path = 'projects/' . $this->analysis->project_id .'/Base/results/report.json';
                    Storage::disk('local')->put($path , $contents);

                    $url = "http://" . $this->analysis->host . ":8080/data_points/" . $data_point_id. "/download_result_file?filename=openstudio_results_report.html";
                    $contents = file_get_contents($url);
                    $report_save_path = 'projects/' . $this->analysis->project_id .'/downloads/' . $data_point_id . '.html';
                    Storage::disk('local')->put($report_save_path , $contents);
                }
            }
         }
     }
 }
