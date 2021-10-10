<template>
  <header class="navbar navbar-expand-md navbar-light d-print-none">
    <div class="container-xl">
      <button
        class="navbar-toggler"
        type="button"
        data-bs-toggle="collapse"
        data-bs-target="#navbar-menu"
      >
        <span class="navbar-toggler-icon" />
      </button>
      <h1
        class="
          navbar-brand navbar-brand-autodark
          d-none-navbar-horizontal
          pe-0 pe-md-3
          font-weight-bold
        "
      >
        <router-link class="text-decoration-none" to="/">
          LightPath CDN
        </router-link>
      </h1>
      <div class="navbar-nav flex-row order-md-last">
        <div class="nav-item d-none d-md-flex me-3">
          <div class="btn-list">
            <router-link
              class="btn btn-primary d-none d-sm-inline-block"
              :to="{ name: 'ZonesNew' }"
            >
              New Site
            </router-link>
          </div>
        </div>
        <div class="nav-item dropdown">
          <a
            href="#"
            class="nav-link d-flex lh-1 text-reset p-0"
            data-bs-toggle="dropdown"
            aria-label="Open user menu"
          >
            <user-circle-icon class="avatar avatar-sm bg-transparent" />
            <div class="d-none d-xl-block ps-2">
              <div class="text-capitalize">{{ username }}</div>
              <div class="mt-1 small text-muted text-capitalize">
                {{ role }}
              </div>
            </div>
          </a>
          <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow">
            <a href="#" class="dropdown-item">Settings</a>
            <button class="dropdown-item" type="button" @click="logout">
              Logout
            </button>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import { UserCircleIcon } from '@heroicons/vue/solid';

export default {
  name: 'NavbarTop',
  components: {
    UserCircleIcon,
  },
  computed: {
    ...mapGetters('users', {
      username: 'getUsername',
      role: 'getRole',
    }),
  },
  methods: {
    async logout() {
      await this.$store.dispatch('users/LOGOUT');
      await this.$router.push({ name: 'Login' });
    },
  },
};
</script>
