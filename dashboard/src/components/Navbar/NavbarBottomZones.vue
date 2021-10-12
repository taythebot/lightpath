<template>
  <div class="navbar-expand-md">
    <div class="collapse navbar-collapse" id="navbar-menu">
      <div class="navbar navbar-light">
        <div class="container-xl">
          <ul class="navbar-nav">
            <li
              v-for="route of routes"
              :key="route.route"
              class="nav-item"
              :class="{ active: isCurrentRoute(route.route) }"
            >
              <a class="nav-link" href="./index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <component :is="route.icon" />
                </span>
                <span class="nav-link-title">{{ route.name }}</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import {
  ChartBarIcon,
  LockClosedIcon,
  DatabaseIcon,
  ShieldCheckIcon,
  FilterIcon,
  CogIcon,
} from '@heroicons/vue/outline';

export default {
  name: 'NavbarZones',
  components: {
    ChartBarIcon,
    LockClosedIcon,
    DatabaseIcon,
    ShieldCheckIcon,
    FilterIcon,
    CogIcon,
  },
  setup() {
    const routes = [
      {
        name: 'Analytics',
        icon: ChartBarIcon,
        route: 'ZonesAnalytics',
      },
      {
        name: 'SSL',
        icon: LockClosedIcon,
        route: 'ZonesSSL',
      },
      {
        name: 'Cache',
        icon: DatabaseIcon,
        route: 'ZonesCache',
      },
      {
        name: 'Security',
        icon: ShieldCheckIcon,
        route: 'ZonesSecurity',
      },
      {
        name: 'Edge Rules',
        icon: FilterIcon,
        route: 'ZonesEdgeRules',
      },
      {
        name: 'Settings',
        icon: CogIcon,
        route: 'ZonesSettings',
      },
    ];

    return { routes };
  },
  methods: {
    isCurrentRoute(name) {
      return this.$route.name === name;
    },
  },
};
</script>
