<template>
  <div class="container">

    <h3> Load Duration Curve</h3>
    <div class="row">
      <div class="col-6">
        <label class="typo__label">Runs</label>
        <multiselect v-model="runs" :options="options" :searchable="false" :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a run" @input="switchRuns">
        </multiselect>
      </div>
    </div>

    <div class="mt-3" id="chart" v-if="hasData">
      <v-chart className="chart" :option="option"/>
    </div>

  </div>

</template>

<script>
import {use} from "echarts/core";
import {CanvasRenderer} from "echarts/renderers";
import {LineChart} from "echarts/charts";
import {
  TitleComponent,
  TooltipComponent,
  ToolboxComponent,
  DataZoomComponent,
  LegendComponent,
  VisualMapComponent,
} from "echarts/components";
import VChart, {THEME_KEY} from "vue-echarts";
import Multiselect from 'vue-multiselect'
import D3HeatmapChart from "./D3HeatmapChart.vue"

use([
  CanvasRenderer,
  LineChart,
  TitleComponent,
  TooltipComponent,
  ToolboxComponent,
  DataZoomComponent,
  VisualMapComponent,
  LegendComponent
]);

export default {
  components: {
    VChart,
    Multiselect,
    D3HeatmapChart,
  },
  provide: {
    [THEME_KEY]: "light"
  },
  props: {
    chart_data: Array,
  },
  data() {
    return {
      runs: [],
      load_duration_data: [],
      is_first_load: false,
      options: [],
      option:{},
      default_option: {

        legend: {
          data: ["kW"],
          inactiveColor: '#777',
        },
        color: ['#0818A8'],
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            animation: true,
            type: 'cross',
            lineStyle: {
              width: 2,
              opacity: 1
            }
          }
        },
        xAxis: {
          name:"%",
          min: 0
        },
        yAxis: {
          name: "kW",
        },
        series: [
          {
            name: "kW",
            type: 'line',
            data: [],
            smooth: true,
            showSymbol: false,
            lineStyle: {
              width: 2,
              color: '#0818A8'
            }
          }
        ]
      },
      data: [],
      hasData: true,
    }
  },
  created() {

    this.chart_data.forEach((run) => {

      let first_run = false;
      run.data.forEach((data) => {
        const current_value = {name: data.display_name, value: data.display_name, hasData: true};

        if (data.data === null || data.data === undefined) {
          current_value.hasData = false;
        }

        if (!this.is_first_load) {
          this.is_first_load = true;
          this.runs.push({name: run.name});
        }

        if (data.data !== null && typeof data.data !== undefined && data.display_name === "Total Electricity" && !first_run) {
          this.load_duration_data = this.calculateLoadDuration(data.data);
          first_run = true;
        }

      });

      this.options.push({name: run.name});
    });

    this.processChart();
  },
  methods: {
    calculateLoadDuration(chart_data) {

      let raw_data = chart_data.map(function (item) {
        return {"value": Math.round(Math.max(item[1]) * 100) / 100};
      });

      let sorted_data = raw_data.sort(function (a, b) {
        return b.value - a.value
      });

      let points_usage = [];
      let inc_value = sorted_data[0];

      for (let i = 0; i < sorted_data.length; i++) {
        if (inc_value !== sorted_data[i].value) {
          sorted_data[i].capacity = i * 100 / sorted_data.length;
          points_usage.push(sorted_data[i]);
          inc_value = sorted_data[i].value;
        }
      }

      return points_usage;
    },

    clearChart() {
      let $this = this;

      // We need a timeout to clear the chart
      setTimeout(function () {
        $this.processChart()
      }, 500)
    },

    processChart() {
      this.option = this.default_option
      this.option.series[0].data = this.load_duration_data.map(function (item) {
        return [Math.round(item.capacity * 100) / 100, Math.round(item.value * 100) / 100];
      });
    },
    switchRuns(runs) {

      this.load_duration_data = [];
      this.chart_data.forEach((run) => {

        run.data.forEach((data) => {
          if (data.data !== null && typeof data.data !== undefined && data.display_name === "Total Electricity" && run.name === runs.name) {
            this.load_duration_data = this.calculateLoadDuration(data.data);
          }
        });

        this.clearChart();
      });
    }
  }
}
</script>

<style>
#chart {
  width: 100%;
  height: 550px;
}
</style>
