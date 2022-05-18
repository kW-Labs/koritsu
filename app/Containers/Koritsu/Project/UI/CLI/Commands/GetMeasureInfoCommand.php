<?php

namespace App\Containers\Koritsu\Project\UI\CLI\Commands;

use App\Ship\Parents\Commands\ConsoleCommand;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

/**
 * Class GetMeasureInfoCommand
 *
 */
class GetMeasureInfoCommand extends ConsoleCommand {

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'openstudio:measure_info {project_id} {measure_name} {debug?}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generates Open Studio Measure Info json from project seed file and measure name';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct() {
        parent::__construct();
    }

    function json_validate($string) {
        $result = json_decode($string);

        switch (json_last_error()) {
            case JSON_ERROR_NONE:
                $error = ''; // JSON is valid // No error has occurred
                break;
            case JSON_ERROR_DEPTH:
                $error = 'The maximum stack depth has been exceeded.';
                break;
            case JSON_ERROR_STATE_MISMATCH:
                $error = 'Invalid or Mismatched JSON data.';
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
            return ['error_msg' => $error];
        }

        return $result;
    }

    /**
     * Execute the console command.
     *
     */
    public function handle() {

        $project_id = $this->argument('project_id');
        $measure_name = $this->argument('measure_name');

        $path = 'projects/' . $project_id . '/Base/results/in.osm' ;
        if (Storage::disk('local')->exists($path)) {

            $in_osm_path = Storage::disk('local')->path($path);
            $cmd = 'sudo ' . env('RUBY') . " -r " . env('RUN_MEASURE_INFO') . " -e \"MeasureInfo.compute_measure_arguments_for_model('" . $in_osm_path . "','" . $measure_name . "')\"";
            $process = Process::fromShellCommandline($cmd, null, ['openstudio' => env('OPEN_STUDIO_BIN')]);

            if ($this->argument('debug')) {
                $this->info($cmd);
            }

            try {
                $process->setTimeout(3600);
                $process->start();
                $process->wait();
                $output = $this->json_validate($process->getOutput());
                $this->info(json_encode($output));
            } catch (ProcessFailedException $exception) {
                echo $exception->getMessage();
            }
        }
    }
}
