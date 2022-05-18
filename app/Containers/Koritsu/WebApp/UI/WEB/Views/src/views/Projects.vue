<template>
  <div class="container-sm">

    <div class="row">
      <div class="col align-self-end">

        <template v-if="project_type.length === 1">
          <button class="btn btn-primary btn-sm btn-light float-right">
            <b-link :to="{ name: 'ProjectCreate' , params: { type:project_type[0], weather: weather[0] }}" class="text-white">
              <font-awesome-icon icon="plus"/>
              Add Project
            </b-link>
          </button>

        </template>
        <template v-else>
          <b-dropdown id="dropdown-1" text="Add Project" class="float-right" variant="primary" >
            <b-dropdown-item v-for="(type,index) in project_type" :to="{ name: 'ProjectCreate' , params: { type:type, weather: weather[index]}}" :key="type"
                             class="text-white">

              {{ project_label[index] }}
            </b-dropdown-item>
          </b-dropdown>
        </template>

      </div>
    </div>

    <template v-if="projects !== null">

      <div v-for="project in projects" :key="project.id" class="row mt-4">

        <div class="container-sm project">
          <div class="row project-details">

            <div class="col-md-7 col-sm-7 col-12">
              <div class="row">
                <div class="col-md-8">
                  <h5 class="mt-2">
                    <template v-if="project.analysis">
                      {{ project.data.project_name }}
                    </template>

                  </h5>
                </div>

                <div class="col-md-4">

                  <div class="float-right">

                    <router-link class="btn btn-sm btn-light mt-2"
                                 :to="{ name: 'ProjectEdit', params: { id: project.id , type:project.project_schema, weather: project.weather_schema}}"
                                 v-if=" project.analysis.status === 'completed' && project.analysis ||  (project.analysis.status == null && !project.analysis.openstudio_analysis_id)">
                      <font-awesome-icon icon="pencil-alt"/>
                    </router-link>

                    <a href="#" class="btn btn-sm btn-light mt-2 ml-2"
                       @click="showDeleteProjectConfirmation(project.id, project.data.project_name)"
                       v-if=" project.analysis.status === 'completed' || project.analysis.status === 'unknown' || !project.analysis.status && project.created_at_minutes > 2">
                      <font-awesome-icon icon="trash"/>
                    </a>
                  </div>
                </div>
              </div>
              <div class="row m-2">

                <div class="col">
                  <div class="text-black-50 fw-light small mt-2">
                    <i class="px-2">
                      <font-awesome-icon icon="building"/>
                    </i>
                    <b>{{ project.data.bldg_type_a | deCamelCase }} {{ project.data.building_type | deCamelCase }} </b>
                  </div>
                </div>

                <template v-if="project.analysis">
                  <div class="col" v-if=" project.analysis.status === 'completed'">
                    <Alternative :id="project.analysis.id"
                                 v-if=" project.analysis.results === 'completed normal'"></Alternative>
                  </div>
                </template>


              </div>
            </div>

            <div class="col-md-4 col-sm-4 col-12">

              <template
                  v-if="project.created_at_minutes < 2 || project.analysis.ran_analysis || project.analysis.status == null && project.analysis.openstudio_analysis_id">

                <template v-if="project.created_at_minutes > 2 || project.analysis.status != null">
                  <Status :status="project.analysis.status" :results="project.analysis.results"
                          :name="project.data.project_name"
                          :openstudio_analysis_id="project.analysis.openstudio_analysis_id"
                          :id="project.analysis.id"></Status>
                </template>

                <template v-else>
                  <div class="mt-4">
                    <i class="px-2">
                      <font-awesome-icon icon="spinner" spin/>
                    </i>
                    <span class="processing"> Creating Analysis </span>
                  </div>
                </template>

              </template>

              <div v-else class="mt-3 ml-3">
                <button class="btn btn-sm btn-info"
                        @click="runAnalysis(project.analysis.id,project.data.project_name)"
                >
                  <font-awesome-icon icon="play"/>
                  Re-Run Analysis
                </button>
              </div>

            </div>

            <template
                v-if="project.analysis.status === 'completed' || (project.has_alternative && !project.analysis.ran_analysis)">
              <div class="col-md-1 col-sm-1 col-12" v-if="project.alternativeAnalysis.length">
                <div class="ms-auto">
                  <a class="btn btn-light rounded-circle mt-4 ms-2 accordion-icon" data-toggle="collapse"
                     :href="'#accordion-' + project.id"
                     role="button" aria-expanded="false" :aria-controls="'#accordion-' + project.id">
                    <font-awesome-icon :icon="['fas', 'chevron-up']"/>
                  </a>
                </div>
              </div>
            </template>

          </div>

          <div class="collapse show" :id="'accordion-' +project.id">
            <div v-for="alternative in project.alternativeAnalysis" :key="alternative.id"
                 class="row alternative-details">
              <div class="col-md-12 col-sm-12 col-12">
                <div class="row p-2">

                  <div class="col-md-7 col-sm-7 col-12">
                    <div class="row">
                      <div class="col-md-8">
                        <h5 class="mt-2">
                          <span class="tiny"><font-awesome-icon :icon="['fas', 'caret-right']"/></span>
                          {{ alternative.name }}

                        </h5>
                      </div>
                      <div class="col-md-4">
                        <div class="float-right">
                          <AlternativeEdit :id="alternative.id"
                                           :name="alternative.name"
                                           v-if=" project.analysis.results === 'completed normal'"></AlternativeEdit>

                          <a href="#" class="btn btn-sm btn-light ml-2"
                             @click="showDeleteAlternativeConfirmation(alternative.id, alternative.name)">
                            <font-awesome-icon icon="trash"/>
                          </a>
                        </div>
                      </div>
                    </div>
                    <div class="row">
                      <div class="col">

                        <Measure :id="project.id" :alternative_id="alternative.id"
                                 v-if="project.analysis.status === 'completed'"></Measure>

                        <button class="btn btn-sm btn-light ml-2" v-show="project.analysis.status ==='completed'"
                                @click="showCopyAlternativeAnalysisMeasureConfirmation(alternative.id, alternative.name)">
                          <font-awesome-icon icon="copy"/>
                        </button>

                      </div>
                    </div>
                  </div>

                  <div class="col-md-5 col-sm-5 col-12">

                    <template v-if="project.analysis.ran_analysis && project.analysis.status === 'completed'">

                      <template v-if="alternative.ran_analysis">

                        <Status :status="alternative.status" :results="alternative.results"
                                :id="alternative.id"
                                :is_alternative=true
                                :name="alternative.name"
                                :openstudio_analysis_id="alternative.openstudio_analysis_id"
                                v-if="alternative.status"></Status>

                        <template v-else>
                          <div class="col">
                            <div class="mt-4 mb-4">
                              <i class="px-2">
                                <font-awesome-icon icon="spinner" spin/>
                              </i>
                              <span class="processing"> Creating Alternative Analysis </span>
                            </div>
                          </div>
                        </template>

                      </template>

                      <div v-else class="mt-3 ml-3">
                        <button class="btn btn-sm btn-info"
                                @click="runAlternativeAnalysis(alternative.id,alternative.name)"
                                v-if="alternative.measures.length > 0 ">
                          <font-awesome-icon icon="play"/>
                          Run Analysis
                        </button>
                      </div>
                    </template>

                    <div v-else class="mt-4 ml-3">
                      Pending Re-Run of Analysis
                    </div>

                  </div>
                </div>

                <div class="row">
                  <div class="container">
                    <table class="table table-bordered table-striped mt-2">
                      <tr v-for="(measure,index) in alternative.measures" :key="measure.display_name">
                        <td><img src="https://api.iconify.design/mdi-drag.svg" alt="drag"></td>
                        <td>
                          <div class="row">
                            <div class="col-8">
                              <h6 class="measure mt-3">{{ measure.display_name }}

                              </h6>
                            </div>
                            <div class="col-4">
                              <div class="float-right">
                                <MeasureEdit :id="project.id" :alternative_id="alternative.id"
                                             :schema="measure.schema" :args="measure.arguments"
                                             :description="measure.description"
                                             :display_name="measure.display_name" :measure_name="measure.measure_name"
                                             v-if="project.analysis.status === 'completed'"></MeasureEdit>

                                <a href="#" class="text-muted ml-4"
                                   @click="showDeleteAlternativeAnalysisMeasureConfirmation(alternative.id, measure.measure_name, measure.display_name)">
                                  <font-awesome-icon icon="trash"/>
                                </a>

                                <a class="btn btn-light rounded-circle ml-4 accordion-icon" data-toggle="collapse"
                                   :href="'#accordion-alternative-' + alternative.id + '-' + index"
                                   role="button" aria-expanded="false"
                                   :aria-controls="'#accordion-alternative-' + alternative.id + '-' + index">
                                  <font-awesome-icon :icon="['fas', 'chevron-up']"/>
                                </a>
                              </div>

                            </div>
                          </div>

                          <div class="row">

                            <div class="collapse container"
                                 :id="'accordion-alternative-' + alternative.id + '-' + index">
                              <template v-for="(value, key) in measure.arguments">
                                <b-badge pill variant="light" v-show="key !== 'object'" class="p-2">
                                  {{ returnDisplayName(key, measure.schema.find(x => x.name === key)) }}:
                                  <i>
                                    {{
                                      returnValue(value, measure.schema.find(x => x.name === key))
                                    }}
                                  </i>
                                </b-badge>
                              </template>
                            </div>

                          </div>

                        </td>
                      </tr>

                    </table>
                  </div>
                </div>

              </div>


            </div>
          </div>

        </div>
      </div>

    </template>

    <template v-else>
      <div class="container text-center pt-4">
        <div class="d-block mx-auto mt-4">
          <font-awesome-icon icon="spinner" size="4x" spin/>
        </div>
      </div>
    </template>

  </div>
</template>

<script>
import {mapGetters, mapActions} from "vuex";
import Alternative from '../components/AlternativeComponent.vue'
import AlternativeEdit from '../components/AlternativeEditComponent.vue'
import Measure from '../components/MeasureComponent.vue'
import MeasureEdit from '../components/MeasureEditComponent.vue'
import Status from '../components/StatusComponent.vue'
import project_types from "../schema/project_types.json";

export default {
  data() {
    return {
      project_type: project_types.properties["type"]["enum"],
      project_label: project_types.properties["label"]["enum"],
      weather: project_types.properties["weather"]["enum"],
    }
  },
  components: {Alternative, AlternativeEdit, Measure, MeasureEdit, Status},
  computed: {
    ...mapGetters({
      projects: "auth/projects",
    }),
  },
  created() {
    this.getProjectsAction();
  },
  methods: {
    ...mapActions({
      getProjectsAction: "auth/getProjects",
      deleteProjectAction: "auth/deleteProject",
      deleteAlternativeAnalysisAction: "auth/deleteAlternativeAnalysis",
      deleteAlternativeAnalysisMeasure: "auth/deleteAlternativeAnalysisMeasure",
      runAlternativeAnalysisAction: "auth/runAlternativeAnalysis",
      runAnalysisAction: "auth/runAnalysisAction",
      copyAnalysisAlternatives: "auth/copyAnalysisAlternatives"
    }),

    returnValue(value, schema) {

      if (typeof schema !== 'undefined') {
        if (schema.type === 'Choice') {
          const foundIndex = schema.choice_values.findIndex(x => x === value);
          return schema.choice_display_names[foundIndex];
        } else {
          return value;
        }
      } else {
        return value;
      }

    },
    returnDisplayName(key, schema) {

      if (typeof schema !== 'undefined') {
        return schema.display_name;
      } else {

        const str = key.replace(/_/g, " ");
        return str.replace(
            /\w\S*/g,
            function (txt) {
              return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
            }
        );
      }

    },
    showDeleteProjectConfirmation(project_id, project_name) {

      this.$bvModal.msgBoxConfirm('Please confirm that you want to delete the "' + project_name + '" project.', {
        title: 'Delete Project',
        size: 'sm',
        buttonSize: 'sm',
        okVariant: 'danger',
        okTitle: 'Yes',
        cancelTitle: 'No',
        footerClass: 'p-2',
        hideHeaderClose: false,
      })
          .then(value => {
            if (value) {
              this.deleteProjectAction(project_id).then(() => {
                this.$toasted.show(`Deleted ${project_name} Project`, {
                  theme: "outline",
                  position: "top-right",
                  duration: 5000
                });

              }).catch(err => {
                console.log(err)
              })
            }
          })
          .catch(err => {
            // An error occurred
            console.log(err)
          })
    },
    showDeleteAlternativeConfirmation(analysis_id, alternative_name) {

      this.$bvModal.msgBoxConfirm('Please confirm that you want to delete the "' + alternative_name + '" Alternative.', {
        title: 'Please Confirm',
        size: 'sm',
        buttonSize: 'sm',
        okVariant: 'danger',
        okTitle: 'Yes',
        cancelTitle: 'No',
        footerClass: 'p-2',
        hideHeaderClose: false,
      })
          .then(value => {
            if (value) {
              this.deleteAlternativeAnalysisAction(analysis_id).then(() => {
                this.$toasted.show(`Deleted ${alternative_name} Alternative`, {
                  theme: "outline",
                  position: "top-right",
                  duration: 5000
                });

              }).catch(err => {
                console.log(err)
              })
            }
          })
          .catch(err => {
            // An error occurred
            console.log(err)
          })
    },
    showDeleteAlternativeAnalysisMeasureConfirmation(alternative_analysis_id, measure_name_id, measure_name) {

      this.$bvModal.msgBoxConfirm('Please confirm that you want to delete the "' + measure_name + '" Measure.', {
        title: 'Please Confirm',
        size: 'sm',
        buttonSize: 'sm',
        okVariant: 'danger',
        okTitle: 'Yes',
        cancelTitle: 'No',
        footerClass: 'p-2',
        hideHeaderClose: false,
      })
          .then(value => {
            if (value) {
              this.deleteAlternativeAnalysisMeasure({
                id: alternative_analysis_id,
                name: measure_name_id
              }).then(() => {
                this.$toasted.show(`Deleted ${measure_name} Measure`, {
                  theme: "outline",
                  position: "top-right",
                  duration: 5000
                });

              }).catch(err => {
                console.log(err)
              })
            }
          })
          .catch(err => {
            // An error occurred
            console.log(err)
          })
    },
    showCopyAlternativeAnalysisMeasureConfirmation(alternative_analysis_id, alternative_name) {

      this.$bvModal.msgBoxConfirm('Please confirm that you want to copy the "' + alternative_name + '" Alternative.', {
        title: 'Copy Alternative',
        size: 'sm',
        buttonSize: 'sm',
        okVariant: 'info',
        okTitle: 'Yes',
        cancelTitle: 'No',
        footerClass: 'p-2',
        hideHeaderClose: false,
      })
          .then(value => {


            if (value) {
              this.copyAnalysisAlternatives({id: alternative_analysis_id,}).then(() => {
                this.$toasted.show(`Copied ${alternative_name} Alternative`, {
                  theme: "outline",
                  position: "top-right",
                  duration: 5000
                });

              }).catch(err => {
                console.log(err)
              })
            }
          })
          .catch(err => {
            // An error occurred
            console.log(err)
          })
    },
    async runAlternativeAnalysis(alternative_analysis_id, alternative_analysis_name) {
      try {
        this.runAlternativeAnalysisAction(alternative_analysis_id).then(() => {
          this.$toasted.show(`Running ${alternative_analysis_name} Alternative Analysis `, {
            theme: "outline",
            position: "top-right",
            duration: 5000,
          });
        });
      } catch (err) {
        console.log(err)
      }
    },
    async runAnalysis(analysis_id, project_name) {
      try {
        this.runAnalysisAction(analysis_id).then(() => {
          this.$toasted.show(`Re-Running ${project_name} Analysis `, {
            theme: "outline",
            position: "top-right",
            duration: 5000,
          });

          setTimeout(() => {
            this.getProjectsAction();
          }, 30000)
        });
      } catch (err) {
        console.log(err)
      }
    }
  },
};
</script>

<style>
.tiny {
  font-size: 9pt;
}
</style>
