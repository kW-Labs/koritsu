<template>
  <span class="mt-2">
    <b-button
        v-b-modal.modal-lg
        v-b-modal.modal-tall
        :id="'show-btn'+id"
        class="btn btn-light"
        variant="success"
        @click="$bvModal.show('bv-modal-alternative-edit-' + id)"
    >
        <font-awesome-icon icon="pencil-alt"/>
    </b-button>

    <b-modal v-b-modal.modal-sm :id="'bv-modal-alternative-edit-' + id" hide-footer size="lg">
      <template v-slot:modal-title> Update Alternative </template>
      <div class="d-block">
        <validation-observer ref="observer" v-slot="{ handleSubmit }">
        <b-form @submit.stop.prevent="handleSubmit(onSubmit)">
          <validation-provider
              name="Name"
              :rules="{ required: true, min: 3 }"
              v-slot="validationContext"
          >
            <b-form-group id="alternative-name-group-1" label="Name" label-for="alternative-name-1">
              <b-form-input
                  id="alternative-name-1"
                  name="alternative-name-1"
                  v-model="form.name"
                  class="ml-3"
                  :state="getValidationState(validationContext)"
                  aria-describedby="input-1-live-feedback"
              ></b-form-input>

              <b-form-invalid-feedback id="input-1-live-feedback">{{
                  validationContext.errors[0]
                }}</b-form-invalid-feedback>
            </b-form-group>
          </validation-provider>

          <div class="col-8">
            <b-button class="ml-2 " @click="resetForm()">Reset</b-button>
            <b-button type="submit" class="float-right" variant="primary">Update Alternative</b-button>
          </div>
        </b-form>
    </validation-observer>
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
    name: String,
  },
  created() {
    this.form.name = this.name;
  },
  data: () => ({
    isLoading: false,
    isError: false,
    isLoaded: false,
    showLoading: false,
    form: {name: null},
    validationContext: {},
  }),
  methods: {
    ...mapActions({
      updateAlternativeAnalysisName: "auth/updateAlternativeAnalysisName",
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

          this.updateAlternativeAnalysisName({
            id: this.id,
            name: this.form.name,
          }).then(() => {
            this.$bvModal.hide("bv-modal-alternative-edit-" + this.id);
            this.$toasted.show(`Updated ${this.form.name} Alternative`, {
              theme: "outline",
              position: "top-right",
              duration: 5000,
            });

            setTimeout(() => {
              this.form.name = null;
            },100)
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

      this.$nextTick(() => {
        this.$refs.observer.reset();
      });
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
