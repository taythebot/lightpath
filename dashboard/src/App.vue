<template>
  <router-view v-if="isAuth" />
  <div v-else class="wrapper">
    <navbar-top />
    <navbar-bottom v-if="$route.name !== 'ZoneNew'" />
    <router-view />
  </div>
</template>

<script>
import NavbarTop from "./components/Navbar/NavbarTop";
import NavbarBottom from "./components/Navbar/NavbarBottom";

export default {
  components: {
    NavbarTop,
    NavbarBottom,
  },
  computed: {
    isAuth() {
      return this.$route.name === "Login";
    },
  },
};
</script>
