<template>
  <section class="ftco-section">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-md-12 col-lg-10">
          <div class="wrap d-md-flex">
            <div
                class="text-wrap p-4 p-lg-5 text-center d-flex align-items-center order-md-last"
            >
              <div class="text w-100">
                <h2>Welcome to Koritsu</h2>
                <p>Don't have an account?</p>
                <router-link class="btn btn-white btn-outline-white" :to="{ name: 'Register' }">Sign Up</router-link>

              </div>
            </div>
            <div class="login-wrap p-4 p-lg-5">
              <form class="signin-form" @submit.prevent="login">
                <div class="form-group mb-3">
                  <label class="label" for="name">Username</label>
                  <input
                      v-model="email"
                      type="email"
                      class="form-control"
                      placeholder="email"
                      id="name"
                      required
                  />
                </div>
                <div class="form-group mb-3">
                  <label class="label" for="password">Password</label>
                  <input
                      v-model="password"
                      type="password"
                      class="form-control"
                      placeholder="Password"
                      id="password"
                      required
                  />
                </div>
                <div class="form-group">
                  <button
                      type="submit"
                      class="form-control btn btn-primary submit px-3"
                  >
                    Login
                  </button>
                </div>
                <div class="form-group d-md-flex">
                  <div class="text-center">
                    <router-link :to="{ name: 'ForgotPassword' }">Forgot Password</router-link>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import {mapActions} from 'vuex'

export default {
  name: "Login",
  data() {
    return {
      email: "",
      password: "",
    };
  },
  methods: {
    ...mapActions({
      signInAction: 'auth/signIn'
    }),
    login() {
      this.signInAction({
        email: this.email,
        password: this.password
      }).then(() => {
        if(this.$store.getters["auth/user"]) {
          this.$router.replace('projects')
        }else{
          this.$toasted.show(`Please Check your Inbox to Verify Your Email`, {
            theme: "outline",
            position: "top-right",
            duration: 5000
          });
        }
      }).catch(() => {
        this.$toasted.show(`Invalid email / password. Please try again`, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });

      })
    },

    loginSuccessful(req) {
      console.log(req);
    },

    loginFailed(err) {
      console.log(err);
    },
  },
};
</script>

