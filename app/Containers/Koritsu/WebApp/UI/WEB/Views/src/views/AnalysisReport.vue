<template>
  <div class="container">

    <h3> Building Summary</h3>

    <template v-if="isLoaded">

      <div class="container mt-2">

        <div>
          <p>Building Name: {{ project_name }}</p>
          <p>Total Building Area: {{ total_bldg_floor_area }}</p>
          <p>Weather File: {{ weather_file_name }}</p>
          <p>Building Type: {{ bldg_type_a }}</p>
        </div>

        <b-table striped hover responsive="'sm" :items="items" :fields="fields" head-variant="dark" :bordered=true
                 class="mt-3">
          <template #cell(name)="data">
            <template v-if="data.value.includes('^')">
              {{ data.value.split("^")[0] }} <sup>{{ data.value.split(")")[0].split("^")[1] }}</sup>)
            </template>
            <template v-else>
              {{ data.value }}
            </template>
          </template>
        </b-table>

      </div>

      <div class="container mt-2">
        <AnnualChart :chart_data="annual_overview_data"></AnnualChart>
      </div>

      <div class="container mt-2">
        <TimeSeriesChart :chart_data="time_series_data"></TimeSeriesChart>
      </div>

     <div class="container mt-2">
        <LoadDurationChart :chart_data="time_series_data"></LoadDurationChart>
      </div>

    </template>
    <template v-else>
      <div class="container text-center pt-4">
        <div class="d-block mx-auto mt-4">
          <font-awesome-icon icon="spinner" size="6x" spin/>
        </div>
      </div>
    </template>

  </div>
</template>

<script>
import {validationMixin} from "vuelidate";
import {mapActions} from "vuex";
import AnnualChart from "./AnnualChart.vue";
import TimeSeriesChart from "./TimeSeriesChart.vue";
import LoadDurationChart from "./LoadDurationChart.vue";

export default {
  mixins: [validationMixin],
  components: {AnnualChart, TimeSeriesChart, LoadDurationChart},
  data() {
    return {
      id: this.$route.params.id,
      building_summary_table: {},
      annual_overview_data: [],
      time_series_data: [],
      data: {},
      bldg_type_a: '',
      project_name: '',
      total_bldg_floor_area: '',
      weather_file_name: '',
      fields: [{key: 'name', sortable: true}],
      items: [],
      isLoaded: false,
    };
  },
  created() {
    this.setDefault()
  },
  methods: {
    ...mapActions({
      getAnalysisReportAction: "auth/getReport"
    }),
    setDefault() {
      this.getAnalysisReportAction(this.id).then((results) => {
        this.data = results.data;

        this.project_name = results.project_name;
        this.total_bldg_floor_area = results.total_bldg_floor_area;
        this.bldg_type_a = results.bldg_type_a;
        this.weather_file_name = results.weather_file_name;

        /**
         * @param run
         * @param run.name
         * @param run.annual_overview
         * @param run.building_summary
         * @param run.timeseries
         * @param run.building_summary.data
         **/
        results.data.forEach((run) => {

          this.fields.push({
            key: run.name,
            sortable: true
          });

          let i = 0;
          for (const [, value2] of Object.entries(run.building_summary.data)) {

            const found_row_index = this.items.findIndex(x => x.id === i);
            const my_value = Math.round(value2.value);
            if (found_row_index >= 0) {
              this.items[found_row_index][run.name] = Number(my_value).toLocaleString();
            } else {
              let current_row = {};
              current_row['id'] = i;
              current_row['name'] = value2.display_name;
              current_row[run.name] = Number(my_value).toLocaleString();
              this.items.push(current_row);
            }

            i++;
          }

          let current_annual_data = {};
          current_annual_data.data = run.annual_overview;
          current_annual_data.name = run.name;
          this.annual_overview_data.push(current_annual_data);
          let current_time_series_data = {};
          current_time_series_data.data = run.timeseries;
          current_time_series_data.name = run.name;
          this.time_series_data.push(current_time_series_data);
          this.isLoaded = true;

        });

      });
    },
  }
};
</script>
