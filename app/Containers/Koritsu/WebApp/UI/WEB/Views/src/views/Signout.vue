<template>
    <h1> Logged Out</h1>
</template>

<script>
import {mapActions} from "vuex";
export default {
    mounted() {
        this.signout
    },
    methods:{
          ...mapActions({
            signout: 'auth/signout'
        }),
    }
}
</script>
