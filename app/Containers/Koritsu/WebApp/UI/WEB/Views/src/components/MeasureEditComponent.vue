<template>
  <span>

    <a href="#"
       v-b-modal.modal-lg
       v-b-modal.modal-tall
       class="text-muted"
       :id="'show-btn-edit-' + alternative_id + '-' + measure_name"
       @click="$bvModal.show('bv-modal-measure-edit-' + alternative_id + '-' + measure_name)"
       >
    <font-awesome-icon icon="pencil-alt"/>
      </a>

    <b-modal :id="'bv-modal-measure-edit-' + alternative_id + '-' + measure_name" hide-footer size="lg">
      <template v-slot:modal-title> Edit {{display_name}} Measure </template>
      <div class="d-block">
          <div class="container alternative">
            <p class="blockquote p-4" v-if="description">{{ description }}</p>
            <validation-observer
                id="project"
                ref="observer"
                v-slot="{ handleSubmit }"
            >
              <b-form @submit.stop.prevent="handleSubmit(onSubmit)" inline>
                <div v-for="item in schema" :key="item.name">
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
                            v-if="item.description !== '' && item.description !== null"
                        >
                          <font-awesome-icon icon="info-circle"/>
                        </b-input-group-prepend>

                        <b-form-input
                            :id="item.name"
                            name="project-input-1"
                            type="number"
                            min="0.00"
                            step="0.01"
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
                            min="0"
                            step="1"
                            v-model="form[item.name]"
                            v-else-if="item.type.toLowerCase() === 'number'"
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

                              /**
                               * @param item
                               * @param item.choice_values
                               * @param item.choice_display_names
                               *
                               **/
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
    args: Object,
    schema: Array,
    description: String,
    measure_name: String,
    display_name: String,
    alternative_id: String,
  },
  created() {

    for (const [key, value] of Object.entries(this.args)) {
      this.form[key] = value;
    }

    this.isLoaded = true;
  },
  data: () => ({
    name: null,
    isLoading: false,
    isError: false,
    isLoaded: false,
    submitBtn: "Update Measure",
    showLoading: false,
    form: {},
    validationContext: {},
  }),
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
            schema: this.schema,
            arguments: this.form,
          },
        }).then(() => {

          // Reset Form
          this.isLoading = false;
          this.isLoaded = false;
          this.$forceUpdate();

          this.$bvModal.hide('bv-modal-measure-edit-' + this.alternative_id + '-' + this.measure_name);
          this.$toasted.show(`Updated ${this.display_name} Measure`, {
            theme: "outline",
            position: "top-right",
            duration: 5000,
          });
        });
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
