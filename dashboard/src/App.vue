<template>
  <div class="wrapper">
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
};
</script>
