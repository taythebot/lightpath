<template>
  <div class="page-wrapper">
    <div class="container-xl">
      <div class="page-header d-print-none">
        <div class="row align-items-center">
          <div class="col">
            <div class="page-pretitle">{{ zone.domain }}</div>
            <h2 class="page-title">
              {{ $route.name.split('Zones')[1] }}
            </h2>
          </div>
        </div>
      </div>
    </div>
    <div class="page-body">
      <div class="container-xl">
        <router-view :zone="zone" />
      </div>
    </div>
  </div>
</template>

<script>
import store from '../../store';

// Middleware
const middleware = async (to, next) => {
  let zone = store.getters['zones/getById'](to.params.id);
  if (!zone) {
    // Refresh zones
    await store.dispatch('zones/GET_ALL');
    zone = store.getters['zones/getById'](to.params.id);
    if (!zone) {
      return next({ name: 'ZonesOverview' });
    }
  }

  next();
};

export default {
  name: 'ZoneRoot',
  computed: {
    zone() {
      return this.$store.getters['zones/getById'](this.$route.params.id);
    },
  },
  async beforeRouteEnter(to, _, next) {
    await middleware(to, next);
  },
  async beforeRouteUpdate(to, _, next) {
    await middleware(to, next);
  },
};
</script>
