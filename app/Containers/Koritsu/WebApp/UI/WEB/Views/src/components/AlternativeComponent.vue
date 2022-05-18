<template>
  <span class="mt-2">
    <b-button
        v-b-modal.modal-lg
        v-b-modal.modal-tall
        :id="'show-btn'+id"
        class="btn btn-light"
        variant="success"
        @click="$bvModal.show('bv-modal-alternative-' + id)"
    >
      <i class="px-2"> <font-awesome-icon icon="plus"/></i> Add Alternative
    </b-button>

    <b-modal v-b-modal.modal-sm :id="'bv-modal-alternative-' + id" hide-footer size="lg">
      <template v-slot:modal-title> Add Alternative </template>
      <div class="d-block">
        <validation-observer ref="observer" v-slot="{ handleSubmit }">
        <b-form @submit.stop.prevent="handleSubmit(onSubmit)">
          <validation-provider
              name="Name"
              :rules="{ required: true, min: 3 }"
              v-slot="validationContext"
          >
            <b-form-group id="alternative-name-group" label="Name" label-for="alternative-name">
              <b-form-input
                  id="alternative-name"
                  name="alternative-name"
                  v-model="form.name"
                  class="ml-3"
                  :state="getValidationState(validationContext)"
                  aria-describedby="alternative-name-live-feedback"
              ></b-form-input>

              <b-form-invalid-feedback id="alternative-name-live-feedback">{{
                  validationContext.errors[0]
                }}</b-form-invalid-feedback>
            </b-form-group>
          </validation-provider>

          <div class="col-8">
            <b-button @click="resetForm()">Reset</b-button>
            <b-button type="submit" class="float-right" variant="primary">Add Alternative</b-button>
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
      createAnalysisAlternatives: "auth/createAnalysisAlternatives",
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
        this.createAnalysisAlternatives({
          id: this.id,
          data: {
            name: this.form.name,
          },
        }).then(() => {
          this.$bvModal.hide("bv-modal-alternative-" + this.id);
          this.$toasted.show(`Added ${this.form.name} Alternative`, {
            theme: "outline",
            position: "top-right",
            duration: 5000,
          });
          this.form.name = null;

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
