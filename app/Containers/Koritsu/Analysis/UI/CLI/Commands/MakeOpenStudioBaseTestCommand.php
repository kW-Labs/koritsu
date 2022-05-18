<?php

namespace App\Containers\Koritsu\Analysis\UI\CLI\Commands;

use App\Containers\Koritsu\Project\Models\Project;
use App\Ship\Parents\Commands\ConsoleCommand;
use DirectoryIterator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

/**
 * Class MakeOpenStudioBaseCommand
 *
 */
class MakeOpenStudioBaseTestCommand extends ConsoleCommand {

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'openstudio:tests {debug?}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generates Open Studio Model from json path';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct() {
        parent::__construct();
    }


    private function makeKeyValuePair($proj, $arr): array {

        $new_arr = [];
        foreach ($arr as $k) {
            // TODO: lookup type via schema
            if (isset($proj[$k])) {
                $val = $proj[$k];

                if ((is_bool($val) || $val === "on") || (in_array($k, ['modify_wknd_op_hrs', 'modify_wkdy_op_hrs']))) {
                    $val = strtolower($val) === 'true';
                } else if (is_numeric($val)) {
                    $val = (double) $val;
                }
                $new_arr[$k] = $val;
            }

        }

        return $new_arr;
    }

    private function getWeatherInfo($state, $weather_file_name): array {
        $json_string = file_get_contents(base_path('resources/json/weather_info.json'));
        $data = json_decode($json_string, true);

        foreach ($data as $weather) {
            if (strtolower($weather['state']) == strtolower($state)) {
                if ($weather['location'] == $weather_file_name) {
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
                $error = 'Unknown JSON error occured.';
                break;
        }

        if ($error !== '') {
            // throw the Exception or exit // or whatever :)
            exit($error);
        }

        // everything is OK
        return $result;
    }

    /**
     * Execute the console command.
     *
     * @return array
     */
    public function handle() {

        set_time_limit(9000);

        // TODO: Create function to check if any analyses are running, if so, try again later.
        try {

            $start_id = 999999;
            $dir = new DirectoryIterator('app/Containers/Ruby/test/test_input/');
            foreach ($dir as $fileinfo) {
                if (!$fileinfo->isDot()) {
                    $file = 'app/Containers/Ruby/test/test_input/' . $fileinfo->getFilename();
                    $data_contents = file_get_contents($file);
                    $project_arr = json_decode($data_contents, true);
                    $data = [];
                    $state = $project_arr['state'] ?? 'UT';
                    $location = $project_arr['location'] ?? "Bryce Cnyn Faa Ap";
                    $weather_info = $this->getWeatherInfo($state, $location);
                    $weather_file = $weather_info['weather_file_name'] ?? 'USA_ID_Boise.Air.Terminal.726810_TMY3.epw';
                    $climate_zone = $weather_info['climate_zone'] ?? '5B';
                    $cec_climate_zone = $weather_info['cec_climate_zone'] ?? '1';
                    $data['weather_file_name'] = $weather_file;
                    $data['alternative_name'] = "Base";
                    $start_id++;
                    $data['project_id'] = $start_id;
                    $data['project_name'] = $project_arr['project_name'];
                    $data['measures'] = [];
                    $data['measures'][] = ["name" => "openstudio_results", "arguments" => []];
                    $data['measures'][] = ["name" => "koritsu_run_report", "arguments" => ["run_name" => $data['alternative_name']]];

                    if (isset($project_arr['building_type'])) {
                        // DOE Prototype
                        $data['measures'][] = ['name' => 'create_DOE_prototype_building', 'arguments' => ['building_type' => $project_arr['building_type'], 'template' => $project_arr['template'], 'climate_zone' => $project_arr['climate_zone']]];
                    } else if (isset($project_arr['building_hvac'])) {
                        // DEER Prototype
                        $data['measures'][] = ['name' => 'create_deer_prototype_building', 'arguments' => ['building_hvac' => $project_arr['building_hvac'], 'template' => $project_arr['template'], 'climate_zone' => $project_arr['climate_zone']]];
                        if (isset($project_arr['sce_rate_type'])) {
                            $data['measures'][] = ['name' => 'add_sce_tariffs', 'arguments' => ['option' => $project_arr['sce_rate_type']]];
                        }
                    } else {
                        // DEER OR DOE Quick Model
                        $project_arr['climate_zone'] = strpos($project_arr['template'], 'DEER') !== false ? "CEC T24-CEC" . $cec_climate_zone : "ASHRAE 169-2013-" . $climate_zone;
                        $data['measures'][] = ['name' => 'ChangeBuildingLocation', 'arguments' => ['weather_file_name' => $weather_file, 'climate_zone' => isset($project_arr['climate_zone']) ? $project_arr['climate_zone'] : 'ASHRAE 169-2013-5B']];
                        $data['measures'][] = ['name' => 'create_bar_from_building_type_ratios', 'arguments' => $this->makeKeyValuePair($project_arr, ['bldg_type_a', 'template', 'total_bldg_floor_area', 'floor_height', 'num_stories_above_grade', 'num_stories_below_grade', 'building_rotation', 'ns_to_ew_ratio', 'wwr', 'climate_zone'])];
                        $data['measures'][] = ['name' => 'create_typical_building_from_model', 'arguments' => $this->makeKeyValuePair($project_arr, ['system_type', 'hvac_delivery_type', 'htg_src', 'clg_src', 'swh_src', 'kitchen_makeup', 'onsite_parking_fraction', 'modify_wkdy_op_hrs', 'wkdy_op_hrs_start_time', 'wkdy_op_hrs_duration', 'modify_wknd_op_hrs', 'wknd_op_hrs_start_time', 'wknd_op_hrs_duration', 'unmet_hours_tolerance'])];
                        if (isset($project_arr['sce_rate_type'])) {
                            $data['measures'][] = ['name' => 'add_sce_tariffs', 'arguments' => ['option' => $project_arr['sce_rate_type']]];
                        }
                        $data['measures'][] = ['name' => 'sce_environmental_impact_factors', 'arguments' => ['climate_zone' => "9"]];
                    }

                    $json = json_encode($data);
                    $cmd = 'cd ' . env('RUN_WORKING_DIRECTORY') . '; sudo ' . env('RUBY') . " " . env('RUN_BASE') . " '$json' " . env('OPEN_STUDIO_META') . " " . str_replace('http://', '', env('OPEN_STUDIO_IP'));
                    $process = Process::fromShellCommandline($cmd, null);

                    if ($this->argument('debug')) {
                        $this->info($cmd);
                    }

                    $response = [];
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
                }
            }

        } catch (ModelNotFoundException $e) {
            $this->info('Project ID Not Found');
        }


    }
}
