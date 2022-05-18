<template>
  <div class="cover-container d-flex w-100 h-100 p-3 mx-auto flex-column">
  <main class="px-3">
    <h1>Thank You For Verifying Your Email</h1>
    <p class="lead">
      <router-link class="btn btn-primary" :to="{ name: 'Login' }">Login</router-link>
    </p>
  </main>
  </div>
</template>

<script>
export default {
  name: "VerifiedEmail",
  components: {},
};
</script>
