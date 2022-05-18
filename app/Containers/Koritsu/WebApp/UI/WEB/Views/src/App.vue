<template>
  <div>
    <TheNavigation v-if="!isLogin"/>
    <div class="container content">
      <router-view/>
    </div>
  </div>
</template>

<script>
import TheNavigation from './components/TheNavigation.vue'

export default {
  components: {TheNavigation},
  computed: {
  isLogin() {
     return this.$route.name === 'Login'
  }
  }
}
</script>
