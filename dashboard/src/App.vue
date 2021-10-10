<template>
  <router-view v-if="isAuth" />
  <div v-else class="wrapper">
    <navbar-top />
    <navbar-bottom-zones v-if="showNavbarZone" />
    <navbar-bottom-default v-else />
    <router-view />
  </div>
</template>

<script>
import NavbarTop from './components/Navbar/NavbarTop';
import NavbarBottomDefault from './components/Navbar/NavbarBottomDefault';
import NavbarBottomZones from './components/Navbar/NavbarBottomZones';

export default {
  components: {
    NavbarTop,
    NavbarBottomDefault,
    NavbarBottomZones,
  },
  computed: {
    isAuth() {
      return this.$route.name === 'Login';
    },
    showNavbarZone() {
      return this.$route.matched.find(({ name }) => name === 'Zones');
    },
  },
};
</script>
