<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\Jobs;

use App\Containers\Koritsu\AlternativeAnalysis\Tasks\GetAlternativeAnalysisStatusTask;
use App\Ship\Parents\Jobs\Job;
use Exception;
use Illuminate\Support\Facades\Storage;
use Log;

/**
 * Class CheckAnlysisStatus
 */
 class CheckAlternativeAnalysisStatusJob extends Job
 {
     private object $alternative_analysis;
     public function __construct(object $alternative_analysis) {
         $this->alternative_analysis = $alternative_analysis;
     }

     public function handle() {

         // TODO: Check and Stop this if running for days?
         try {
             $status = app(GetAlternativeAnalysisStatusTask::class)->run($this->alternative_analysis);
             if (isset($status['status']['analysis']['status'])) {
                 if ($status['status']['analysis']['status'] !== 'completed') {
                     sleep(20);
                     dispatch(new CheckAlternativeAnalysisStatusJob($this->alternative_analysis));
                 } else {

                     sleep(15); // Add a minor delay just in case file is not ready
                     $data_point_id = $status['status']['analysis']['data_points'][0]['id'];
                     $data_point_status = $status['status']['analysis']['data_points'][0]['status_message'];
                     if ($data_point_status === 'completed normal') {

                         $url = "http://" . $this->alternative_analysis->host . ":8080/data_points/" . $data_point_id . "/download_result_file?filename=data_point.zip";
                         $contents = file_get_contents($url);
                         $zip_path = 'projects/' . $this->alternative_analysis->analysis->project_id . '/downloads/' . $data_point_id . '.zip';
                         Storage::disk('local')->put($zip_path, $contents);

                         $url = "http://" . $this->alternative_analysis->host . ":8080/data_points/" . $data_point_id . "/download_result_file?filename=koritsu_run_report_report.json";
                         $contents = file_get_contents($url);
                         $alternative_folder = 'projects/' . $this->alternative_analysis->analysis->project_id . '/alternative_' . $this->alternative_analysis->id  . '/';
                         if(!file_exists($alternative_folder)){
                             Storage::makeDirectory($alternative_folder);
                         }
                         $path = $alternative_folder . 'results/report.json';
                         Storage::disk('local')->put($path, $contents);

                         $url = "http://" . $this->alternative_analysis->host . ":8080/data_points/" . $data_point_id . "/download_result_file?filename=openstudio_results_report.html";
                         $contents = file_get_contents($url);
                         $report_save_path = 'projects/' . $this->alternative_analysis->analysis->project_id . '/downloads/' . $data_point_id . '.html';
                         Storage::disk('local')->put($report_save_path, $contents);

                     }
                 }

             }

         } catch (Exception $e) {
             Log::info($e->getMessage());
         }

     }

 }

