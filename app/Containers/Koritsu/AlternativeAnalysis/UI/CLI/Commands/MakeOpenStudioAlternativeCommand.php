<?php

namespace App\Containers\Koritsu\AlternativeAnalysis\UI\CLI\Commands;

use App\Containers\Koritsu\AlternativeAnalysis\Models\AlternativeAnalysis;
use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Parents\Commands\ConsoleCommand;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

/**
 * Class MakeOpenStudioAlternativeCommand
 *
 */
class MakeOpenStudioAlternativeCommand extends ConsoleCommand {

    protected string $schema_path = "Containers/Koritsu/WebApp/UI/WEB/Views/src/schema/";

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'openstudio:alternative {project_id} {alternative_analysis_id} {debug?}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generates Open Studio Alternative Analysis from Project Seed File and Alternative Measures';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct() {
        parent::__construct();
    }

    private function makeKeyValuePair($proj, $arr, $arr_rename, $schema): array {

        $new_arr = [];
        foreach ($arr as $k) {

            if (isset($proj[$k])) {
                $val = $proj[$k];

                if(isset($schema->{$k})) {

                    if ($schema->{$k}->type ==="boolean") {
                        $val = strtolower($val) === 'true';
                    } else if ($schema->{$k}->type ==="number"){
                        $val = intval($val);
                    } else if ($schema->{$k}->type ==="integer"){
                        $val = floatval($val);
                    }
                }

                $new_arr[$k] = $val;
            }

        }

        foreach ($arr_rename as $i => $my_arr) {

            $k = $my_arr['field'];
            $a = $my_arr['argument'];
            if (isset($proj[$k])) {
                $val = $proj[$k];

                if(isset($schema->{$k})) {

                    if ($schema->{$k}->type ==="boolean") {
                        $val = strtolower($val) === 'true';
                    } else if ($schema->{$k}->type ==="number"){
                        $val = intval($val);
                    } else if ($schema->{$k}->type ==="integer"){
                        $val = floatval($val);
                    }
                }

                $new_arr[$a] = $val;
            }

        }

        return $new_arr;
    }

    private function getWeatherInfo($state, $location, $schema): array {

        $json_string = file_get_contents(app_path('Containers/Koritsu/WebApp/UI/WEB/Views/src/schema/' . $schema . '.json'));
        $data = json_decode($json_string, true);
        foreach ($data as $weather) {
            if (strtolower($weather['state']) == strtolower($state)) {
                if ($weather['location'] == $location) {
                    return $weather;
                }
            }
        }

        return [];
    }

    function json_validate($string) {
        // decode the JSON data
        $result = json_decode($string);

        // switch and check possible JSON errors
        switch (json_last_error()) {
            case JSON_ERROR_NONE:
                $error = ''; // JSON is valid // No error has occurred
                break;
            case JSON_ERROR_DEPTH:
                $error = 'The maximum stack depth has been exceeded.';
                break;
            case JSON_ERROR_STATE_MISMATCH:
                $error = 'Invalid or malformed JSON.';
                break;
            case JSON_ERROR_CTRL_CHAR:
                $error = 'Control character error, possibly incorrectly encoded.';
                break;
            case JSON_ERROR_SYNTAX:
                $error = 'Syntax error, malformed JSON.';
                break;
            // PHP >= 5.3.3
            case JSON_ERROR_UTF8:
                $error = 'Malformed UTF-8 characters, possibly incorrectly encoded.';
                break;
            // PHP >= 5.5.0
            case JSON_ERROR_RECURSION:
                $error = 'One or more recursive references in the value to be encoded.';
                break;
            // PHP >= 5.5.0
            case JSON_ERROR_INF_OR_NAN:
                $error = 'One or more NAN or INF values in the value to be encoded.';
                break;
            case JSON_ERROR_UNSUPPORTED_TYPE:
                $error = 'A value of a type that cannot be encoded was given.';
                break;
            default:
                $error = 'Unknown JSON error occurred.';
                break;
        }

        if ($error !== '') {
            // throw the Exception or exit // or whatever :)
            exit($error);
        }

        // everything is OK
        return $result;
    }

    public function generateMeasuresFromSchemas($project_arr): array {

        // Make Measures using Project Schema and Measure Arguments
        $current_project_schema = $project_arr['project_schema']  ?? "default_model";
        $project_schema_json = app_path($this->schema_path . $current_project_schema . '.json');

        $generated_measures = [];
        if(file_exists($project_schema_json)) {
            $project_schema_string = file_get_contents($project_schema_json);
            $project_schema = json_decode($project_schema_string);
            $measure_schema_json_file = app_path($this->schema_path . $current_project_schema . '_measures_alternatives.json');

            if (file_exists($measure_schema_json_file)) {
                $json_string = file_get_contents($measure_schema_json_file);
                $project_measures_schema = json_decode($json_string);
                $measures = $project_measures_schema->properties->measures->enum;
                foreach ($measures as $measure) {
                    $measure_json = app_path($this->schema_path . $measure . '.json');

                    if (file_exists($measure_json)) {
                        $current_measure = json_decode(file_get_contents($measure_json));

                        $arr_pair = [];
			$arr_pair_rename = [];
		   	$obj = $current_measure->properties ?? $current_measure->arguments;
                        foreach ($obj as $argument => $val) {
                            if (isset($val->title)) {
                                $arr_pair_rename[] = ["argument" => $argument, "field" =>$val->title];
                            } else {
                                $arr_pair[] = $argument;
                            }
                        }

			$arguments = $this->makeKeyValuePair($project_arr, $arr_pair, $arr_pair_rename, $project_schema->properties);
	                $name = isset($current_measure->id) ?$current_measure->id: $current_measure->name;
                        $generated_measures[] = ['name' => $name, 'arguments' => $arguments];
                    }
                }
            }
        }

        return $generated_measures;
    }

    /**
     * Execute the console command.
     *
     */
    public function handle() {

        set_time_limit(3600);

        try {
            $project_id = $this->argument('project_id');
            $alternative_analysis_id = $this->argument('alternative_analysis_id');
            $alternative_analysis = AlternativeAnalysis::findOrFail($alternative_analysis_id);
            $alternative_analysis_arr = $alternative_analysis->getAttribute('data');
            $measures = $alternative_analysis_arr['measures'];
            $project = Project::findOrFail($project_id);
            $project_arr = json_decode($project->getAttribute('data'), true);
            $data = [];

            // Get Weather Info
            $state = $project_arr['state'] ?? 'UT';
            $location = $project_arr['location'] ?? "Bryce Cnyn Faa Ap";
            $weather_schema = $project_arr['weather_schema'] ?? "weather_default";
            $weather_info = $this->getWeatherInfo($state, $location, $weather_schema);
            $weather_file = $weather_info['weather_file_name'] ?? 'USA_ID_Boise.Air.Terminal.726810_TMY3.epw';
            $project_arr['climate_zone_num'] = $weather_info['climate_zone'] ?? '5B';
            $project_arr['cec_climate_zone'] = $weather_info['cec_climate_zone'] ?? '1';
            $project_arr['cec_climate_zone_num'] = $weather_info['cec_climate_zone_num'] ?? '1';
            $data['weather_file_name'] = $project_arr['weather_file_name'] = $weather_file;

            // Project Info
            $data['alternative_name'] = $project_arr['alternative_name'] = $project_arr['run_name'] = "alternative_" . $alternative_analysis_id;
            $data['project_id'] = $project->getAttribute('id');
            $data['project_name'] = $project_arr['project_name'];

            // Measure Info
            $pre_measures = $this->generateMeasuresFromSchemas($project_arr);

            $measures_arguments = [];
            foreach ($measures as $measure) {
                $name = $measure['measure_name'] ?? ($measure['name'] ?? '');
                $arguments = $measure['arguments'];

                $invalid_measures = ['Create_Variable_Speed_RTU', 'Fan_Assist_Night_Ventilation', 'Replace_Water_Heater_Mixed_With_Thermal_Storage_Chilled_Water', 'Nze_Hvac'];
                if (in_array($name, $invalid_measures)) {
                    $name = strtolower($name);
                }

                $measures_arguments[] = ['name' => $name, 'arguments' => $arguments];
            }

            $data['measures'] = array_merge($pre_measures,$measures_arguments);
            $json = json_encode($data);

            // Verify no Environment Variable are blank
            $envs =["RUN_WORKING_DIRECTORY","RUBY","RUN_BASE","OPEN_STUDIO_META","OPEN_STUDIO_IP"];
            $no_blank_env = true;
            foreach ($envs as $env){
                if(empty($env)){
                    $no_blank_env = false;
                    break;
                }
            }

            if ($no_blank_env) {

                $cmd = 'cd ' . env('RUN_WORKING_DIRECTORY') . '; sudo ' . env('RUBY') . " " . env('RUN_BASE') . " '$json' " . env('OPEN_STUDIO_META') . " " . str_replace('http://', '', env('OPEN_STUDIO_IP'));
                $process = Process::fromShellCommandline($cmd);

                if ($this->argument('debug')) {
                    $this->info($cmd);
                }

                try {
                    $process->setTimeout(3600);
                    $process->start();
                    $process->wait();
                    $output = $this->json_validate($process->getOutput());
                    $output_analysis_id = isset($output->analysis_id) ? trim($output->analysis_id) : "";
                    $response = ['analysis_id' => $output_analysis_id, 'data' => $data, 'host' => env('OPEN_STUDIO_IP'), 'results' => $output];

                    $this->info(json_encode($response));
                } catch (ProcessFailedException $exception) {
                    echo $exception->getMessage();
                }
            }else{
                $this->info("Blank Environment variables");
            }

        } catch (ModelNotFoundException $e) {
            $this->info('Project ID Not Found');
        }
    }
}
