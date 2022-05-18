<template>
  <section class="ftco-section">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-6">
          <div class="wrap">
            <div class="p-4">
              <validation-observer
                  id="resetPassword"
                  ref="observer"
                  v-slot="{ handleSubmit }"
              >
                <b-form @submit.stop.prevent="handleSubmit(onSubmit)">

                  <validation-provider
                      name="password"
                      :rules="{
                      required: true,
                      min: 8,
                      max: 20,
                      regex: /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$/,
                    }"
                      v-slot="validationContext"
                  >
                    <b-form-group
                        id="registration-input-group-3"
                        label="Password"
                        label-for="registration-input-3"
                    >
                      <b-form-input
                          id="registration-input-3"
                          name="registration-input-3"
                          v-model="form.password"
                          type="password"
                          :state="getValidationState(validationContext)"
                          aria-describedby="input-3-live-feedback"
                      ></b-form-input>

                      <b-form-invalid-feedback id="input-3-live-feedback">{{
                          validationContext.errors[0]
                        }}
                      </b-form-invalid-feedback>
                    </b-form-group>
                  </validation-provider>

                  <b-button type="submit" variant="primary">
                    {{ submittBtn }}

                    <font-awesome-icon icon="spinner" spin v-if="showLoading"/>
                  </b-button>
                  <b-button class="mr-4 float-right" @click="resetForm()">Reset</b-button>

                </b-form>
              </validation-observer>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import {validationMixin} from "vuelidate";
import {mapActions} from 'vuex'

export default {
  name: "ResetPassword",
  mixins: [validationMixin],
  data() {
    return {
      submittBtn: "Update Password",
      showLoading: false,
      form: {
        password: null,
      },
    };
  },
  methods: {
    ...mapActions({
      resetPasswordAction: 'auth/resetPassword'
    }),
    onSubmit() {
      this.showLoading = true;
      this.submittBtn = "Updating Password";
      this.resetPasswordAction({
        email: this.$route.query.email,
        token: this.$route.query.token,
        password: this.form.password,
      }).then(() => {
        this.showLoading = false;
        this.submittBtn =  "Update Password";
        this.$toasted.show(`Password has been updated`, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });

        setTimeout(() => {
          this.$router.replace('login')
        }, 2500);

      }).catch(err => {
        this.showLoading = false;
        this.submittBtn =  "Update Password";
        this.$toasted.show(err.response.data.message, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });

        setTimeout(() => {
          this.$router.replace('login')
        }, 2500);

      })
    },
    getValidationState({dirty, validated, valid = null}) {
      return dirty || validated ? valid : null;
    },
    resetForm() {
      this.form = {
        password: null,
      };

      this.$nextTick(() => {
        this.$refs.observer.reset();
      });
    },
  },
};
</script>

