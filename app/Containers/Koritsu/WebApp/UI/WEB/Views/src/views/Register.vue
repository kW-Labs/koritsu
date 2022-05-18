<template>
  <div id="registration-six" class="container mb-3 mt-3">
    <div class="container">

      <div class="row justify-content-center">
        <div class="col-6 card pb-5 wrap">
          <h1 class="pb-3 pt-4">Create Account</h1>

          <validation-observer
              id="registration"
              ref="observer"
              v-slot="{ handleSubmit }"
          >
            <b-form @submit.stop.prevent="handleSubmit(onSubmit)">
              <validation-provider
                  name="Name"
                  :rules="{ required: true, min: 3 }"
                  v-slot="validationContext"
              >
                <b-form-group
                    id="registration-input-group-1"
                    label="Name"
                    label-for="registration-input-1"
                >
                  <b-form-input
                      id="registration-input-1"
                      name="registration-input-1"
                      v-model="form.name"
                      :state="getValidationState(validationContext)"
                      aria-describedby="input-1-live-feedback"
                  ></b-form-input>

                  <b-form-invalid-feedback id="input-1-live-feedback">{{
                      validationContext.errors[0]
                    }}
                  </b-form-invalid-feedback>
                </b-form-group>
              </validation-provider>

              <validation-provider
                  name="Email"
                  rules="required|email"
                  v-slot="validationContext"
              >
                <b-form-group
                    id="registration-input-group-2"
                    label="Email"
                    label-for="registration-input-2"
                >
                  <b-form-input
                      id="registration-input-2"
                      name="registration-input-2"
                      v-model="form.email"
                      type="email"
                      :state="getValidationState(validationContext)"
                      aria-describedby="input-2-live-feedback"
                  ></b-form-input>

                  <b-form-invalid-feedback id="input-2-live-feedback">{{
                      validationContext.errors[0]
                    }}
                  </b-form-invalid-feedback>
                </b-form-group>
              </validation-provider>

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
</template>

<script>
import {validationMixin} from "vuelidate";
import {mapActions} from "vuex";

export default {
  mixins: [validationMixin],
  data() {
    return {
      submittBtn: "Create Account",
      showLoading: false,
      form: {
        name: null,
        email: null,
        password: null,
      },
    };
  },
  methods: {
    ...mapActions({
      signUpAction: "auth/signUp",
    }),
    getValidationState({dirty, validated, valid = null}) {
      return dirty || validated ? valid : null;
    },
    resetForm() {
      this.form = {
        name: null,
        email: null,
        password: null,
      };

      this.$nextTick(() => {
        this.$refs.observer.reset();
      });
    },
    showToast(msg) {
      this.$toasted.show(msg, {
        theme: "outline",
        position: "top-right",
        duration: 5000
      });
    },
    async onSubmit() {
      this.submittBtn = "Creating Account ..."
      this.showLoading = true;

      if (/@kw-engineering.com\s*$/.test(this.form.email) || /@sce.com\s*$/.test(this.form.email)) {
        await this.signUpAction({
          name: this.form.name,
          email: this.form.email,
          password: this.form.password,
        })
            .then((response) => {
                  this.showLoading = false;
                  this.submittBtn = "Creating Account"
                  if (response) {

                    this.showLoading = false;
                    this.submittBtn = "Creating Account"
                    this.$toasted.show(`Created Account, Please check your email`, {
                      theme: "outline",
                      position: "top-right",
                      duration: 5000
                    });

                    setTimeout(() => {
                      this.$router.replace("/");
                    }, 1500);

                  } else {

                    let $this = this;
                    Object.keys(response.errors).forEach(function (item) {
                      $this.showToast(response.errors[item][0]);
                    });

                  }
                }
            ).catch((err) => {
              this.showLoading = false;
              this.submittBtn = "Creating Account"
              console.log(err);
            });

      } else {
        this.showLoading = false;
        this.submittBtn = "Creating Account"
        this.$toasted.show(`Invalid Domain / password. Please try again`, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });
      }


    },
  },
};
</script>

