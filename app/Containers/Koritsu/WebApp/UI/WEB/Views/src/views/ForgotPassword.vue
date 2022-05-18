<template>
  <section class="ftco-section">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-6">
          <div class="wrap">
            <div class="p-4">
              <form class="signin-form" @submit.prevent="reset">
                <div class="form-group mb-3">
                  <label class="label" for="name">Email</label>
                  <input
                      v-model="email"
                      type="email"
                      class="form-control"
                      placeholder="email"
                      id="name"
                      required
                  />
                </div>

                <div class="form-group">
                  <button
                      type="submit"
                      class="form-control btn btn-primary submit px-3"
                  >
                    Reset Password
                  </button>
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
  name: "ForgotPassword",
  data() {
    return {
      email: "",
    };
  },
  methods: {
    ...mapActions({
      forgotPasswordAction: 'auth/forgotPassword'
    }),
    reset() {
      this.forgotPasswordAction({
        email: this.email,
      }).then(() => {
        this.$toasted.show(`Please Check your Inbox to Reset Your Password`, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });

        setTimeout(() => {
          this.$router.replace('login')
        }, 2500);

      }).catch(() => {
        this.$toasted.show(`That Email was not found. Please try again`, {
          theme: "outline",
          position: "top-right",
          duration: 5000
        });

      })
    },
  },
};
</script>

