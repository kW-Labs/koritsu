<?php

namespace App\Containers\Koritsu\Analysis\Tasks;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\Analysis\Data\Repositories\AnalysisRepository;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Parents\Tasks\Task;
use Illuminate\Contracts\Filesystem\FileNotFoundException;
use Illuminate\Support\Facades\Storage;
use stdClass;

/**
 * Class GetAnalysisReportTask.
 *
 */
class GetAnalysisReportTask extends Task {

    /**
     * @var  AnalysisRepository
     */
    protected AnalysisRepository $repository;

    /**
     * GetAllAnalysesTask constructor.
     *
     * @param AnalysisRepository $repository
     */
    public function __construct(AnalysisRepository $repository) {
        $this->repository = $repository;
        ini_set('memory_limit', '4024M');
    }

    /**
     * @throws FileNotFoundException
     */
    public function run($analysis): stdClass {

        $json_obj = new stdClass();
        $json_obj->data = [];

        $dirs = Storage::disk('local')->directories('projects/' . $analysis->project_id );
        $alternatives = AlternativeAnalysis::where('analysis_id',$analysis->id)->get()->pluck('ran_analysis','id')->toArray();
        $alternatives_names = AlternativeAnalysis::where('analysis_id',$analysis->id)->get()->pluck('name','id')->toArray();

        foreach($dirs as $dir){
            $dirs_arr = explode("/",$dir);
            $dir_name = strtolower($dirs_arr[2]);
            $is_alternative =  !in_array($dir_name, ['downloads', 'weather']);
            $report = $dir . "/results/report.json";
            $has_report = Storage::disk('local')->exists($report);
            if($has_report && $is_alternative){

                if ($dir_name === 'base'){
                    array_unshift($json_obj->data,json_decode(Storage::disk('local')->get($report)));
                }else {

                    // Only Include Alternatives that ran analysis
			$id_ = explode('_',$dir_name);

		    if(isset($alternatives[$id_[1]])){
                        if($alternatives[$id_[1]]) {
                           $alt_report = json_decode(Storage::disk('local')->get($report));
                            $alt_report->name = $alternatives_names[$id_[1]];
                            $json_obj->data[] = $alt_report;
		        }
		    }
                }
            }
        }

        $project =Project::findOrFail($analysis->project_id);
        $data =  json_decode($project->getAttribute('data'));
        $analysis_data =  json_decode($analysis->getAttribute('data'));
        $json_obj->project_name = $data->project_name ?? '';
        $json_obj->total_bldg_floor_area =  $data->total_bldg_floor_area ??  '';
        $json_obj->bldg_type_a = $data->bldg_type_a ?? $data->building_type ?? '';
        $json_obj->weather_file_name = $analysis_data->weather_file_name ?? '';
        return $json_obj;
    }

}

