<template>

  <nav class="navbar navbar-expand-lg navbar-light bg-light" role="navigation">
    <div class="container">
      <a class="navbar-brand" href="#"></a>
      <button class="navbar-toggler border-0" type="button" data-toggle="collapse" data-target="#exCollapsingNavbar">
        &#9776;
      </button>
      <div class="collapse navbar-collapse" id="exCollapsingNavbar">
        <ul class="nav navbar-nav">
          <li class="nav-item">
            <router-link class="nav-link px-2 link-white" :to="{ name: 'Home' }">
              <font-awesome-icon icon="home"/>
              Home
            </router-link>
          </li>

          <template v-if="authenticated">
            <li>
              <router-link class="nav-link px-2 link-white" :to="{ name: 'Projects' }">
                <font-awesome-icon icon="building"/>
                Projects
              </router-link>
            </li>
          </template>
        </ul>

        <ul class="nav navbar-nav flex-row justify-content-between ml-auto">
          <template v-if="authenticated">
            <li class="nav-item dropdown">
              <a class="nav-link dropdown-toggle" href="#" id="userMenu" data-toggle="dropdown" aria-haspopup="true"
                 aria-expanded="false">
                <font-awesome-icon icon="user-circle"/>
                {{ user.name }}</a>
              <div class="dropdown-menu user-menu" aria-labelledby="userMenu">
                <router-link class="nav-link px-2 link-white" :to="{ name: 'ChangePassword' }">
                  <font-awesome-icon icon="asterisk"/>
                  Change Password
                </router-link>

                <a href="#" class="dropdown-item link-dark" @click.prevent="signOut">
                  <font-awesome-icon icon="sign-out-alt"/>

                  Signout</a>

              </div>
            </li>
          </template>

          <template v-else>
            <li class="nav-item">
              <router-link class="btn btn-outline-primary" :to="{ name: 'Login' }">Login</router-link>
            </li>
          </template>
        </ul>

      </div>
    </div>
  </nav>

</template>

<script>
import {mapGetters, mapActions} from "vuex";

export default {
  computed: {
    ...mapGetters({
      authenticated: "auth/authenticated",
      user: "auth/user",
    }),
  },

  methods: {
    ...mapActions({
      signOutAction: "auth/signOut",
    }),
    signOut() {
      this.signOutAction().then(() => {
        this.$router.replace({
          name: "Home",
        });
      });
    },
  },
};
</script>

<style>
#userMenu{
  min-width: 200px;
}
</style>
