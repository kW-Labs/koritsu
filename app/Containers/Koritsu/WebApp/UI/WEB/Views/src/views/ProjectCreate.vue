<template>
  <div class="container">
    <div class="row justify-content-center" v-if="schema">
      <div class="col-6 card pb-5 wrap">
        <h2 class="pb-3 pt-4">Create {{ type }} Project</h2>

        <validation-observer id="project" ref="observer" v-slot="{ handleSubmit }">
          <b-form @submit.stop.prevent="handleSubmit(onSubmit)">
            <div v-for="(item,key) in properties" :key="item.title">
              <validation-provider
                  :name="item.title"
                  :rules="{ required: item.required }"
                  v-slot="validationContext"
              >
                <b-input-group
                    :id="'project-input-group-' + item.title"
                    v-if="item.type === 'boolean'"
                    class="my-3"
                >
                  <b-form-checkbox
                      :id="item.title"
                      v-model="form[key]"
                      :name="item.title"
                      :state="getValidationState(validationContext)"
                      :aria-describedby="'input-live-feedback-' + item.title"
                      :required="item.required"
                  >

                    <span class="mx-3">{{ item.title }}</span>
                  </b-form-checkbox>


                  <b-form-invalid-feedback id="input-1-live-feedback">
                    {{ validationContext.errors[0] }}
                  </b-form-invalid-feedback>
                </b-input-group>
                <b-form-group
                    :id="'project-input-group-' + item.title"
                    :label="item.title"
                    :label-for="'project-input-' + item.title"
                    class="my-3"
                    v-else
                >
                  <b-input-group>
                    <b-input-group-prepend
                        is-text
                        v-b-tooltip.left
                        :title="item.description"
                        v-if="item.description !== ''"
                    >
                      <font-awesome-icon icon="info-circle"/>
                    </b-input-group-prepend>

                    <b-form-input
                        :id="item.title"
                        name="project-input-1"
                        type="number"
                        :min="typeof item.min !== undefined ? item.min: 0"
                        :max="typeof item.max !== undefined ? item.max: null"
                        step="1"
                        :class="(item.description !== '') ? 'form-control-info':'form-control'"
                        v-model="form[key]"
                        v-if="item.type === 'integer'"
                        :state="getValidationState(validationContext)"
                        :aria-describedby="'input-live-feedback-' + item.title"
                        :required="item.required"
                    ></b-form-input>

                    <b-form-input
                        :id="item.title"
                        name="project-input-1"
                        type="number"
                        :class="(item.description !== '') ? 'form-control-info':'form-control'"
                        :min="typeof item.min !== undefined ? item.min: 0.01"
                        :max="typeof item.max !== undefined ? item.max: null"
                        step="0.01"
                        v-model="form[key]"
                        v-else-if="item.type.toLowerCase() === 'number' || item.type.toLowerCase() === 'double'"
                        :state="getValidationState(validationContext)"
                        :aria-describedby="'input-live-feedback-' + item.title"
                        :required="item.required"
                    ></b-form-input>

                    <b-form-select :class="(item.description !== '') ? 'form-control form-control-info':'form-control'"
                                   v-model="form[key]"
                                   v-else-if="item.type === 'string' && isUndefined(item.enum) && key !=='state' &&  key !=='location' "
                                   :required="item.required"
                                   v-on:change="check_if_condition(key)"
                                   :options="returnObjectForOptions(item.enum, item.enum)">
                    </b-form-select>


                    <b-form-select :class="(item.description !== '') ? 'form-control form-control-info':'form-control'"
                                   v-model="form[key]"
                                   v-on:change="updateLocations(false)"
                                   v-else-if="item.type === 'string' && isUndefined(item.enum) && key ==='state'  &&  key !=='location'"
                                   :required="item.required"
                                   :options="returnObjectForOptions(states, states)">
                    </b-form-select>

                    <b-form-select :class="(item.description !== '') ? 'form-control form-control-info':'form-control'"
                                   v-model="form[key]"
                                   v-else-if="item.type === 'string' && isUndefined(item.enum) &&  key ==='location'"
                                   :required="item.required"
                                   :options="returnObjectForOptions(locations, locations)">
                    </b-form-select>

                    <b-form-input
                        :id="item.title"
                        name="project-input-1"
                        type="text"
                        v-model="form[key]"
                        v-else
                        :state="getValidationState(validationContext)"
                        :class="(item.description !== '') ? 'form-control-info':'form-control'"
                        :aria-describedby="'input-live-feedback-' + item.title"
                        :required="item.required"
                    ></b-form-input>
                  </b-input-group>

                  <b-form-invalid-feedback id="input-1-live-feedback">
                    {{ validationContext.errors[0] }}
                  </b-form-invalid-feedback>
                </b-form-group>

              </validation-provider>
            </div>

            <b-button type="submit" variant="primary">
              {{ submitBtn }}

              <font-awesome-icon icon="spinner" spin v-if="showLoading"/>
            </b-button>

            <b-button class="mr-4 float-right" @click="resetForm()">Reset</b-button>

          </b-form>

        </validation-observer>
      </div>
    </div>
  </div>
</template>

<script>
import {validationMixin} from "vuelidate";
import {mapActions} from "vuex";

export default {
  mixins: [validationMixin],
  data() {
    return {
      selected_schema: this.$route.params.type,
      weather_schema: this.$route.params.weather,
      weather:[],
      weather_json: null,
      submitBtn: "Create Project",
      showLoading: false,
      type: '',
      if:{},
      then:{},
      else:{},
      has_if_condition:[],
      states: [],
      locations: [],
      form: {
        project_name: "",
        project_schema: "",
        weather_schema: "",
      },
      validationContext: {},
      schema: null,
      properties: null
    };
  },
  async created() {

    this.form.project_schema = this.selected_schema;
    this.form.weather_schema = this.weather_schema;
    this.schema = await import('../schema/' + this.selected_schema);
    this.properties = this.schema.properties;
    this.if = this.schema.if;
    this.then = this.schema.then;
    this.else = this.schema.else;

    this.type = this.schema.title;
    this.setDefault()

    // Flag Field with if Conditions
    if(this.if){
      for (const [field] of Object.entries(this.if.properties)) {
        this.has_if_condition[field] = true;
        this.check_if_condition(field);
      }
    }

    this.weather_json = await import('../schema/' + this.weather_schema)

    let my_states = [];
    for (const [, value] of Object.entries(this.weather_json)) {
      if (value.state) {
        my_states.push(value.state)
        this.weather.push(value)
      }
    }
    this.states = [...new Set(my_states)];
    this.updateLocations(true);

  },
  methods: {
    ...mapActions({
      createProjectAction: "auth/createProject"
    }),
    check_if_condition(current_field) {
      if( this.has_if_condition[current_field]){

        // TODO: Update this for more complex scenarios
        // Match If Condition
        let matched_values = false;
        if(this.if){
          for (const [field, obj] of Object.entries(this.if.properties)) {
            if (current_field === field &&  obj.const === this.form[current_field]){
              matched_values = true
            }
          }
        }

        // TODO: Update this for anything other than enum scenarios
        // Matched If Condition
        if(matched_values){
          for (const [field, obj] of Object.entries(this.then.properties)) {
            this.properties[field].enum = obj.enum
          }
        }else{
          for (const [field, obj] of Object.entries(this.else.properties)) {
            this.properties[field].enum = obj.enum
          }
        }

      }
    },
    setDefault() {
      for (const [key, value] of Object.entries(this.properties)) {
        this.form[key] = value.default
      }
    },
    updateLocations(initial) {
      const my_location = this.weather.filter((weather_info) => {
        if (weather_info.state === this.form.state) {
          return weather_info.location;
        }
      });
      this.locations = my_location.map((weather_info) => weather_info.location);

      if (!initial) {
        this.form.location = this.locations[0];
      }

    },
    isUndefined(value) {
      return typeof (value) !== 'undefined'
    },
    returnObjectForOptions(obj) {
      let objs = [];
      objs.push({'text': '--- Select an Option --', 'value': null, 'disabled': true});

      obj.forEach(element => {
        const key = typeof element.key === 'undefined' ? element : element.key;
        const value = typeof element.value === 'undefined' ? element : element.value;
        objs.push({'value': key, 'text': value});
      })

      return objs;

    },
    getValidationState({dirty, validated, valid = null}) {
      return dirty || validated ? valid : null;
    },
    resetForm() {
      this.form = {};

      this.$nextTick(() => {
        this.$refs.observer.reset();
      });
    },
    onSubmit() {

      this.submitBtn = "Updating Project ...";
      this.showLoading = true;

      this.createProjectAction({name: this.form.project_name, data: this.form})
          .then((response) => {
            this.showLoading = false;
            this.submitBtn = "Update Project";
            if (!response) {
              this.$router.replace("/projects");
            } else {
              if ("errors" in response) {
                Object.keys(response.errors).forEach(function (item) {
                  alert(response.errors[item][0]);
                });
              }
            }
          })
          .catch((err) => {
            this.showLoading = false;
            this.submitBtn = "Update Project";
            console.log(err);
          });
    }
  }
};
</script>
