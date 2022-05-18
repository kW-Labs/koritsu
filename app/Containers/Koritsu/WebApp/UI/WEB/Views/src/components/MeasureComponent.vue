<template>
  <span>
    <b-button
        v-b-modal.modal-lg
        v-b-modal.modal-tall
        id="show-btn"
        class="btn btn-light"
        variant="success"
        @click="$bvModal.show('bv-modal-measure-' + id)"
    >
      <i class="px-2"> <font-awesome-icon icon="plus"/></i> Add Measure
    </b-button>

    <b-modal :id="'bv-modal-measure-' + id" hide-footer size="lg">
      <template v-slot:modal-title> Add Measure </template>
      <div class="d-block">
        <div class="form-group">
          <label class="col-sm-5 col-form-label" :for="'measure-' + id"
          >Measure</label
          >
          <b-form-select
              class="form-control"
              v-model="measure_name"
              v-on:change="getMeasure"
              :options="measures"
              :id="'measure-' + id"
          >
          </b-form-select>
        </div>

        <div v-if="isError">Error!</div>
        <div v-else-if="isLoading">
          <div class="container">
            <div class="text-center p-4">
              <font-awesome-icon icon="spinner" size="4x" spin/>
            </div>
          </div>
        </div>
        <div v-else>
          <div class="container alternative">
            <p class="blockquote p-4" v-if="isLoaded">{{ description }}</p>
            <validation-observer
                id="project"
                ref="observer"
                v-slot="{ handleSubmit }"
                v-show="isLoaded"
            >
              <b-form @submit.stop.prevent="handleSubmit(onSubmit)" inline>
                <div v-for="item in dataArguments" :key="item.name">
                  <validation-provider
                      :name="item.name"
                      :rules="{ required: item.required }"
                      v-slot="validationContext"
                  >
                    <b-input-group
                        :id="'project-input-group-' + item.name"
                        v-if="item.type.toLowerCase() === 'boolean'"
                        class="mt-3"
                    >
                      <b-form-checkbox
                          :id="item.name"
                          v-model="form[item.name]"
                          :name="item.name"
                          :state="getValidationState(validationContext)"
                          :aria-describedby="'input-live-feedback-' + item.name"
                      >
                        <span class="mr-3">{{ item.display_name }}</span>
                      </b-form-checkbox>

                      <b-form-invalid-feedback id="input-1-live-feedback"
                      >{{ validationContext.errors[0] }}
                      </b-form-invalid-feedback>
                    </b-input-group>
                    <b-form-group
                        :id="'project-input-group-' + item.name"
                        :label="item.display_name"
                        :label-for="'project-input-' + item.name"
                        class="mt-3"
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
                            :id="item.name"
                            name="project-input-1"
                            type="number"
                            :min="typeof item.min !== undefined ? item.min: 0"
                            :max="typeof item.max !== undefined ? item.max: null"
                            step="1"
                            v-model="form[item.name]"
                            v-if="item.type.toLowerCase() === 'integer'"
                            :state="getValidationState(validationContext)"
                            :aria-describedby="'input-live-feedback-' + item.name"
                            :required="item.required"
                        ></b-form-input>

                        <b-form-input
                            :id="item.name"
                            name="project-input-1"
                            type="number"
                            :min="typeof item.min !== undefined ? item.min: 0.01"
                            :max="typeof item.max !== undefined ? item.max: null"
                            step="0.01"
                            v-model="form[item.name]"
                            v-else-if="item.type.toLowerCase() === 'number' || item.type.toLowerCase() === 'double'"
                            :state="getValidationState(validationContext)"
                            :aria-describedby="'input-live-feedback-' + item.name"
                            :required="item.required"
                        ></b-form-input>

                        <b-form-select
                            class="form-control"
                            v-model="form[item.name]"
                            v-else-if="item.type.toLowerCase() === 'choice'"
                            :required="item.required"
                            :options="
                            returnObjectForOptions(
                              item.choice_values,
                              item.choice_display_names
                            )
                          "
                        >
                        </b-form-select>

                        <b-form-input
                            :id="item.name"
                            name="project-input-1"
                            type="text"
                            v-model="form[item.name]"
                            v-else
                            :state="getValidationState(validationContext)"
                            :aria-describedby="'input-live-feedback-' + item.name"
                            :required="item.required"
                        ></b-form-input>
                      </b-input-group>

                      <b-form-invalid-feedback id="input-1-live-feedback"
                      >{{ validationContext.errors[0] }}
                      </b-form-invalid-feedback>
                    </b-form-group>
                  </validation-provider>
                </div>

                <div class="container ">
                  <b-button type="submit" variant="primary">
                    {{ submitBtn }}
                    <font-awesome-icon icon="spinner" spin v-if="showLoading"/>
                  </b-button>

                  <b-button class="mr-4 float-right" @click="resetForm()">Reset</b-button>
                </div>
              </b-form>
            </validation-observer>
          </div>
        </div>
      </div>
    </b-modal>
  </span>
</template>
<script>
import {validationMixin} from "vuelidate";
import {mapActions} from "vuex";

export default {
  mixins: [validationMixin],
  props: {
    id: String,
    alternative_id: String,
  },

  data: () => ({
    measures: [
      {text: "--- Select an Measure --", value: null, disabled: true},
    ],
    measure_name: null,
    display_name: null,
    name: null,
    dataArguments: [],
    description: null,
    isLoading: false,
    isError: false,
    isLoaded: false,
    submitBtn: "Add Measure",
    showLoading: false,
    form: {},
    validationContext: {},
  }),
  async created() {
    this.alternative_measures = await import('../schema/alternative_measures.json')

    for (const [, value] of Object.entries(this.alternative_measures)) {
      if (value.text) {
        this.measures.push(value)
      }
    }

  },
  methods: {
    ...mapActions({
      updateAlternativeAnalysisMeasures: "auth/updateAlternativeAnalysisMeasures",
      getMeasureInfoAction: "auth/getMeasureInfo",
    }),
    returnObjectForOptions(obj, obj_display) {
      let objs = [];
      objs.push({
        text: "--- Select an Option --",
        value: null,
        disabled: true,
      });

      obj.forEach((value, key) => {
        objs.push({value: value, text: obj_display[key]});
      });

      return objs;
    },
    async onSubmit() {
      try {
        this.updateAlternativeAnalysisMeasures({
          id: this.alternative_id,
          data: {
            measure_name: this.measure_name,
            display_name: this.display_name,
            description: this.description,
            schema: this.dataArguments,
            arguments: this.form,
          },
        }).then(() => {

          // Reset Form
          this.isLoading = false;
          this.isLoaded = false;
          this.$forceUpdate();

          this.$bvModal.hide("bv-modal-measure-" + this.id);
          this.$toasted.show(`Added ${this.display_name} Measure`, {
            theme: "outline",
            position: "top-right",
            duration: 5000,
          });
          this.measure_name = null;

        });
      } catch (err) {
        this.isError = true;
      } finally {
        this.isLoading = false;
      }
    },
    async getMeasure() {
      try {

        const get_local_json = this.measures.filter(x => x.value === this.measure_name)
        const model_dependent = get_local_json[0].model_dependent

        if (model_dependent) {
          this.isError = false;
          if (this.measure_name) {
            this.isLoading = true;

            await this.getMeasureInfoAction({
              id: this.id,
              measure_name: this.measure_name,
            }).then((response) => {

              this.resetForm();
              this.dataArguments = response.arguments;
              this.description = response.description;
              this.display_name = response.display_name;

              for (const [key, value] of Object.entries(this.dataArguments)) {
                this.form[value.name] = this.dataArguments[key].default_value;
              }

              this.isLoaded = true;
              this.$forceUpdate();
            });
          }
        }else{

          const response = await import('../schema/' + this.measure_name + ".json")
          this.resetForm();
          this.dataArguments = response.arguments;
          this.description = response.description;
          this.display_name = response.display_name;

          for (const [key, value] of Object.entries(this.dataArguments)) {
            this.form[value.name] = this.dataArguments[key].default_value;
          }

          this.isLoaded = true;
          this.$forceUpdate();
        }
      } catch (err) {
        this.isError = true;
      } finally {
        this.isLoading = false;
      }
    },
    getValidationState({dirty, validated, valid = null}) {
      return dirty || validated ? valid : null;
    },
    resetForm() {
      this.form = {};

    },
  },
};
</script>
<style scoped>
.spinner-border {
  width: 80px;
  height: 80px;
}

.large-checkbox {
  font-size: 18px;
}
</style>
