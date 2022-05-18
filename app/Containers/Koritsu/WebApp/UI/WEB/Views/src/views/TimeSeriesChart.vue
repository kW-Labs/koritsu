<template>
  <div class="container">

    <h3> Timeseries Data</h3>
    <div class="row">
      <div class="col-6">
        <label class="typo__label">Fuel Types</label>
        <multiselect v-model="fuel_type" :multiple="true" :options="fuel_options" :searchable="false"
                     :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a fuel type"
                     @select="checkFuelType"
                     @input="switchFuelType">
        </multiselect>
      </div>
      <div class="col-6">
        <label class="typo__label">Runs</label>
        <multiselect v-model="runs" :multiple="true" :options="options" :searchable="false" :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a run" @input="switchRuns">
        </multiselect>
      </div>
    </div>

    <div class="mt-3" id="chart" v-if="hasData">
      <v-chart className="chart" :option="option"/>
    </div>

    <div class="clearfix"></div>
    <D3HeatmapChart :chart_data="data" :fuel_options="fuel_options" :options="options"
                    v-if="hasDataCalendarHeatmap"></D3HeatmapChart>

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

const blue_hex = [
  {color: "#0000FF"},
  {color: "#7DF9FF"},
  {color: "#0096FF"},
  {color: "#088F8F"},
  {color: "#0818A8"},
  {color: "#6082B6"},
  {color: "#0437F2"},
  {color: "#4169E1"},
  {color: "#000080"},
  {color: "#3F00FF"},
  {color: "#7393B3"},
  {color: "#1434A4"},
  {color: "#6F8FAF"},
  {color: "#191970"},
  {color: "#0047AB"},
  {color: "#00FFFF"},
  {color: "#00008B"},
  {color: "#0F52BA"},
  {color: "#6495ED"},
  {color: "#1F51FF"},
  {color: "#4682B4"}];

const red_hex = [
  {color: "#A52A2A"},
  {color: "#4A0404"},
  {color: "#C41E3A"},
  {color: "#630330"},
  {color: "#9A2A2A"},
  {color: "#770737"},
  {color: "#D2042D"},
  {color: "#880808"},
  {color: "#6E260E"},
  {color: "#8B0000"},
  {color: "#D22B2B"},
  {color: "#811331"},
  {color: "#A52A2A"},
  {color: "#D70040"},
  {color: "#7B1818"},
  {color: "#7C3030"},
  {color: "#A42A04"},
  {color: "#800000"},
  {color: "#954535"},
  {color: "#722F37"},
{color: "#800020"}];

const current_option = {
  tooltip: {
    trigger: 'axis',
    position: function (pt) {
      return [pt[0], '10%'];
    }
  },
  title: {
    left: 'center',
    text: 'Baseline Load Profile\n Usage vs Time',
  },
  toolbox: {
    feature: {
      dataZoom: {
        yAxisIndex: 'none'
      },
      restore: {},
      saveAsImage: {}
    }
  },
  legend: {
    data: [],
    top: 40,
    left: 'center'
  },
  dataZoom: [
    {
      show: true,
      realtime: true,
      start: 98,
      end: 100
    },

    {
      type: 'inside',
      realtime: true,
      start: 65,
      end: 85
    }
  ],
  xAxis: {
    type: 'time',
    boundaryGap: false,
    axisLine: {onZero: false}
  },
  yAxis: [{
    name: '',
    type: 'value',
    max: 'dataMax'
  },
    {
      name: '',
      max: 'dataMax',
      type: 'value',
    }],
  series: []
};

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
      fields: [],
      items: [],
      runs: [],
      units: [],
      fuel_type: [],
      is_first_fuel_type: false,
      options: [],
      option: {},
      fuel_options: [],
      data: [],
      lastFuelTypeValue: '',
      hasData: true,
      hasDataFuelType: true,
      hasDataCalendarHeatmap: true,
    }
  },
  created() {

    this.chart_data.forEach((run, index) => {

      run.data.forEach((data, key) => {
        const current_value = {name: data.display_name, value: data.display_name, hasData: true};

        if (data.data === null || data.data === undefined) {
          current_value.hasData = false;
        }

        if (!this.is_first_fuel_type) {
          this.is_first_fuel_type = true;
          this.fuel_type.push(current_value);
          this.runs.push({name: run.name});
        }

        if (data.data !== null && typeof data.data !== undefined) {
          let records = [];
          let heatMapRecords = [];
          for (const [, value2] of Object.entries(data.data)) {
            records.push([value2[0], Math.round(parseFloat(value2[1]))]);
            heatMapRecords.push({date: value2[0], value: Math.round(parseFloat(value2[1]))});
          }
          this.data.push({index: index, key: key, data: records, heatmap_data: heatMapRecords, units: data.units});
        }

        const foundIndex = this.fuel_options.findIndex(x => x.name === data.display_name);
        if (foundIndex < 0) {
          this.fuel_options.push(current_value);
        }
      });

      this.options.push({name: run.name});
    });

    this.processChart(this.fuel_type, this.runs);
  },
  methods: {

    parseDate(date_string) {
      let d = date_string.split(/\D+/g).map(function (v) {
        return parseInt(v, 10);
      });
      return new Date(d[0], d[1] - 1, d[2], d[3], d[4], d[5]);
    },

    clearChart(fuel_value, runs) {
      this.option = current_option;
      this.hasData = false;
      let $this = this;

      // We need a timeout to clear the chart
      setTimeout(function () {
        $this.processChart(fuel_value, runs)
      }, 100)
    },

    processChart(fuel_types, runs) {

      this.option = Object.assign({}, current_option);
      this.option.legend.data = [];
      this.option.series = [];
      this.option.yAxis[0].name = '';
      this.option.yAxis[1].name = '';
      this.units = [];
      this.fields = [];
      this.items = [];

      let series_set_kW = {
        name: '',
        type: 'line',
        lineStyle: {
          width: 1
        },
        emphasis: {
          focus: 'series'
        },
        itemStyle: {},
        data: []
      };

      let series_set_Btu = {
        name: '',
        type: 'line',
        lineStyle: {
          width: 1
        },
        emphasis: {
          focus: 'series'
        },
        itemStyle: {},
        data: []
      };

      let i = 0;
      this.chart_data.forEach((run, index) => {

        const found_run_index = runs.findIndex(x => x.name === run.name);
        if (found_run_index >= 0) {

          this.fields.push({
            key: run.name
          });

          for (const [key, value] of Object.entries(run.data)) {

            const found_row_index = fuel_types.findIndex(x => x.name === value.display_name);
            const current_name = run.name + " - " + value.display_name + " " + value.units;

            if (found_row_index >= 0) {
              if (fuel_types[found_row_index].hasData) {

                const found_unit_index = this.units.findIndex(x => x === value.units);
                if (found_unit_index < 0) {
                  this.units.push(value.units);
                  this.option.yAxis[this.units.length - 1].name = value.units;
                }

                const found_data_row_index = this.data.findIndex(x => x.index === index && x.key === parseInt(key));
                let current_series_set = value.units === 'kW' ? Object.assign({}, series_set_kW) : Object.assign({}, series_set_Btu);
                const shift = found_data_row_index + index;
                current_series_set.itemStyle = value.units === 'kW' ? blue_hex[shift] : red_hex[shift];
                current_series_set.name = current_name;
                current_series_set.yAxisIndex = this.units.length > 1 ? 1 : 0;
                current_series_set.data = found_data_row_index >= 0 ? this.data[found_data_row_index].data : [];

                if (fuel_types[found_row_index].hasData) {
                  this.hasData = true;
                }

                this.option.series.push(current_series_set);
              }
            }

          }

        }
        i++;

      });


      setTimeout(() => {
        this.hasDataCalendarHeatmap = true;
      }, 100)

    },
    checkFuelType(fuelType) {
      const found_row_index = this.fuel_options.findIndex(x => x.name === fuelType.value);
      if (found_row_index >= 0) {
        if (!this.fuel_options[found_row_index].hasData) {
          this.hasDataFuelType = false;
          alert("No Data for " + fuelType.value);
          this.lastFuelTypeValue = fuelType.value;
          return false;
        }
      }
    },
    switchFuelType(fuelType) {
      if (this.hasDataFuelType) {
        this.clearChart(fuelType, this.runs);
      } else {
        const found_fuel_type_index = this.fuel_type.findIndex(x => x.name === this.lastFuelTypeValue);
        if (found_fuel_type_index >= 0) {
          this.fuel_type.splice(found_fuel_type_index, 1);
        }
        this.hasDataFuelType = true;
      }
    },
    switchRuns(runs) {
      this.clearChart(this.fuel_type, runs);
    }
  }
};
</script>

<style>
#chart {
  width: 100%;
  height: 550px;
}
</style>
