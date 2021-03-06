<?php

/**
 * @apiGroup           Analyses
 * @apiName            getAnalysisStatus
 * @api                {get} /v1/analyses/:id/status Get Analysis Status from Open Studio Server
 * @apiDescription     Get Analysis Status from Open Studio Server for a particular Analysis ID
 *
 * @apiVersion         1.0.0
 * @apiPermission      Authenticated User
 *
 * @apiParam           {Number} id Analysis ID
 *
 * @apiExample {REST} Get Status
 * /analyses/39n0Z12OZGKERJgW/status
 *
 * @apiSuccessExample  {json}  Success-Response:
 * HTTP/1.1 200 OK
 * {
 * "status": {
 *  "analysis": {
 *      "_id": "23c9bfbc-433f-4bce-b33c-ad96021e996f",
 *      "id": "23c9bfbc-433f-4bce-b33c-ad96021e996f",
 *      "status": "completed",
 *      "analysis_type": "batch_run",
 *      "run_flag": true,
 *      "exit_on_guideline_14": 0,
 *      "total_datapoints": 1,
 *      "jobs": [
 *          {
 *          "index": 0,
 *          "analysis_type": "single_run",
 *          "status": "completed",
 *          "status_message": ""
 *          },
 *          {
 *          "index": 1,
 *          "analysis_type": "batch_run",
 *          "status": "post-processing finished",
 *          "status_message": ""
 *          }
 *      ],
 *      "data_points": [
 *          {
 *          "_id": "96c4a20a-bacc-4f4f-bc1d-6f59cbb834eb",
 *          "id": "96c4a20a-bacc-4f4f-bc1d-6f59cbb834eb",
 *          "name": "Single Run Autogenerated",
 *          "analysis_id": "23c9bfbc-433f-4bce-b33c-ad96021e996f",
 *          "status": "completed",
 *          "status_message": "completed normal"
 *          }
 *      ]
 *   }
 *  }
 * }
 *
 * @apiUse             GeneralSuccessMultipleResponse
 */

use App\Containers\Koritsu\Analysis\UI\API\Controllers\Controller;
use Illuminate\Support\Facades\Route;

Route::get('analyses/{id}/status', [Controller::class, 'getStatus'])
    ->name('api_get_analysis_status')
    ->middleware(['auth:api']);
