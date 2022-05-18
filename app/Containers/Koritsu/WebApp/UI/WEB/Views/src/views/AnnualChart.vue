<template>
  <div class="container">

    <h3> Annual Overview</h3>
    <div class="row">
      <div class="col-6">
        <label class="typo__label">Fuel Type</label>
        <multiselect v-model="fuel_type" :options="fuel_options" :searchable="false" :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a fuel type"
                     @select="switchFuelType">
        </multiselect>
      </div>
      <div class="col-6">
        <label class="typo__label">Runs</label>
        <multiselect v-model="runs" :options="options" :multiple="true" :close-on-select="false"
                     :clear-on-select="false" :preserve-search="true" placeholder="Pick some" label="name"
                     track-by="name" :preselect-first="true" @input="switchRuns">
          <template slot="selection" slot-scope="{ values, search, isOpen }">
            <span class="multiselect__single" v-if="values.length &amp;&amp; !isOpen">
              {{ values.length }} options selected</span>
          </template>
        </multiselect>
      </div>
    </div>

    <div class="mt-3" id="chart">
      <v-chart className="chart" :option="option" :loading="loading"
               v-if="has_data"/>
    </div>

    <div class="mt-3" id="pt-2">

      <h3> Comparison Table</h3>

      <div class="row" v-if="has_multiple_runs">
        <div class="col-6">
          <label class="typo__label">Fuel Type</label>
          <multiselect v-model="selectFuelCompare" :options="fuel_options" :searchable="false" :close-on-select="true"
                       :show-labels="false" label="name" track-by="name" placeholder="Pick a fuel type"
                       @select="switchCompareFuelType">
          </multiselect>
        </div>
        <div class="col-6">
          <label class="typo__label">Run</label>
          <multiselect v-model="selectCompare" :options="runOptions" :searchable="false" :close-on-select="true"
                       :show-labels="false" label="name" track-by="name" placeholder="Pick a run"
                       @select="switchCompareRuns">
          </multiselect>
        </div>
      </div>


      <b-table striped hover :items="items" :fields="fields" head-variant="dark" :bordered=true class="mt-3"
               v-if="has_data"></b-table>

      <div class="mt-3" v-else>
        <h3> NO Chart Data. :(</h3>
      </div>

    </div>

  </div>

</template>

<script>
import {use} from "echarts/core";
import {CanvasRenderer, SVGRenderer} from "echarts/renderers";
import {BarChart} from "echarts/charts";
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent
} from "echarts/components";
import VChart, {THEME_KEY} from "vue-echarts";

import Multiselect from 'vue-multiselect'

use([
  CanvasRenderer,
  BarChart,
  TitleComponent,
  TooltipComponent,
  CanvasRenderer,
  SVGRenderer,
  LegendComponent
]);

const current_option = {
  title: {
    left: 'center'
  },
  tooltip: {
    trigger: 'axis',
    axisPointer: {
      type: 'shadow'
    }
  },
  legend: {
    orient: 'horizontal',
    left: 'center',
    top: 'bottom',
    emphasis: {
      focus: 'series',
    },
    data: [],

  },
  xAxis: [
    {
      type: 'category',
      data: [],
    }
  ],
  yAxis: [
    {
      type: 'value'
    }
  ],
  series: []
};

export default {
  components: {
    VChart,
    Multiselect
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
      runOptions: [],
      selectCompare: null,
      selectFuelCompare: null,
      loading: true,
      is_first_fuel_type: false,
      fuel_type: {},
      initOptions: {
        renderer: "canvas"
      },
      options: [],
      fuel_options: [],
      has_data: false,
      has_multiple_runs: false,
      option: {},
    }
  },
  created() {

    this.chart_data.forEach((run) => {
      this.options.push({name: run.name});
      this.runs.push({name: run.name});

      if (run.name.toLowerCase() !== 'base') {
        this.runOptions.push({name: run.name});

        this.has_multiple_runs = true;
        if (this.selectCompare === null) {
          this.selectCompare = {name: run.name};
        }
      }

      for (const [key, value] of Object.entries(run.data)) {

        const found_run_index = this.fuel_options.findIndex(x => x.name === value.unit);

        if (found_run_index < 0) {
          const current_value = {name: value.unit, value: key};
          if (!this.is_first_fuel_type) {
            this.is_first_fuel_type = true;
            this.fuel_type = current_value;
            this.selectFuelCompare = current_value;
          }

          this.fuel_options.push(current_value);
        }
      }
    });

    this.processChart(this.fuel_type.value, this.runs);
  },
  methods: {

    clearChart(fuel_value, runs) {
      this.option = current_option;
      this.has_data = false;
      let $this = this;
      // We need a timeout to clear the chart
      setTimeout(function () {
        $this.processChart(fuel_value, runs)
      }, 100)
    },

    processChart(fuel_type, runs) {

      this.option = Object.assign({}, current_option);
      this.option.xAxis[0].data = [];
      this.option.legend.data = [];
      this.option.title.text = '';
      this.option.series = [];
      this.loading = false;

      const colorList = ["#ef1c20", // Heating
        "#0071bd", // Cooling
        "#f7df10", // Interior Lighting
        "#dec310", // Exterior Lighting
        "#4a4d4a", // Interior Equipment
        "#31314a", // Exterior Equipment
        "#ff79ad", // Fans
        "#632c94", // Pumps
        "#131399", // Heat Rejection
        "#805408", // Humidification
        "#991313", // Heat Recovery
        "#ffb339", // Water Systems
        "#29aae7", // Refrigeration
        "#ff9913" // Generators
      ];

      if (runs.length > 0) {

        let run_count = 0;
        this.chart_data.forEach((run) => {

          const found_run_index = runs.findIndex(x => x.name === run.name);

          if (found_run_index >= 0) {
            this.option.xAxis[0].data.push(run.name);

            for (const [key, value] of Object.entries(run.data)) {

              if (key === fuel_type) {
                let i = 0;
                this.option.title.text = 'Annual Energy Use \n (' + value.unit + ')';

                for (const [key2, value2] of Object.entries(value.data)) {

                  if (value2 > 0) {
                    const found_series_index = this.option.series.findIndex(x => x.name === key2);

                    if (!this.has_data) {
                      this.has_data = true;
                    }

                    const my_value = Math.round(value2);
                    if (found_series_index >= 0) {
                      this.option.series[found_series_index].data.push(my_value);
                    } else {
                      this.option.legend.data.push(key2);
                      const current_series = {
                        name: key2,
                        type: 'bar',
                        stack: 'Annual Energy Use',
                        emphasis: {
                          focus: 'series',
                        },
                        data: [my_value],
                        itemStyle: {
                          color: colorList[i]
                        }
                      };

                      if (run_count > 0) {
                        let count = 0;
                        while (count < (run_count)) {
                          current_series.data.unshift(0);
                          count++;
                        }
                      }
                      this.option.series.push(current_series);
                    }

                  }

                  i++;
                }
              }
            }
            run_count++;
          }

        });
      } else {
        this.has_data = false;
      }

      this.compareRuns(fuel_type, this.selectCompare !== null ? this.selectCompare.name : null);
    },

    compareRuns(fuel_type, current_run) {

      this.fields = [{key: 'name', sortable: true}];
      this.items = [];
      this.chart_data.forEach((run) => {

        const run_name = run.name.toLowerCase();
        const is_baseline = run_name === 'base';
        const matches_selected_option = current_run === run_name;
        const is_baseline_or_comparison = matches_selected_option || is_baseline;

        if (is_baseline_or_comparison) {
          this.fields.push({
            key: run_name,
            sortable: true
          });

          for (const [key, value] of Object.entries(run.data)) {

            if (key === fuel_type) {
              let i = 0;
              for (const [key2, value2] of Object.entries(value.data)) {

                const my_value = Math.round(value2);
                const found_row_index = this.items.findIndex(x => x.id === i);
                if (found_row_index >= 0) {
                  this.items[found_row_index][run_name] = my_value;
                } else {
                  let current_row = {};
                  current_row['id'] = i;
                  current_row['name'] = key2;
                  current_row[run_name] = my_value;
                  this.items.push(current_row);
                }

                i++;
              }
            }
          }
        }

      });

      if (this.options.length >= 2) {
        this.fields.push({
          key: "savings",
          sortable: true
        });

        this.items.map(d => {
          const savings = (parseFloat(d.base) - parseFloat(d[current_run]));
          d.savings = savings > 0 ? Math.round(savings) : 0;
        })
      }

    },
    switchFuelType(fuelType) {
      this.clearChart(fuelType.value, this.runs)
    },
    switchRuns(runs) {
      this.clearChart(this.fuel_type.value, runs);
    },
    switchCompareFuelType(fuelType) {
      this.compareRuns(fuelType.value, this.selectCompare.name)
    },
    switchCompareRuns(run) {
      this.compareRuns(this.fuel_type.value, run.name);
    }
  }
};
</script>

<style>
#chart {
  width: 100%;
  height: 500px;
}
</style>
