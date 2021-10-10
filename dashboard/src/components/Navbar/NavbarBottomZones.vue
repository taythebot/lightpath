<template>
  <div class="navbar-expand-md">
    <div class="collapse navbar-collapse" id="navbar-menu">
      <div class="navbar navbar-light">
        <div class="container-xl">
          <ul class="navbar-nav">
            <li class="nav-item active">
              <a class="nav-link" href="./index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <home-icon />
                </span>
                <span class="nav-link-title">Analytics</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./form-elements.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block"
                  ><!-- Download SVG icon from http://tabler-icons.io/i/checkbox -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="icon"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    fill="none"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                    <polyline points="9 11 12 14 20 6"></polyline>
                    <path
                      d="M20 12v6a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h9"
                    ></path>
                  </svg>
                </span>
                <span class="nav-link-title">Cache</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./form-elements.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <filter-icon />
                </span>
                <span class="nav-link-title">Edge Rules</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./form-elements.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <shield-check-icon />
                </span>
                <span class="nav-link-title">Security</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./docs/index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <cog-icon />
                </span>
                <span class="nav-link-title">Settings</span>
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
  HomeIcon,
  ShieldCheckIcon,
  FilterIcon,
  CogIcon,
} from '@heroicons/vue/outline';

export default {
  name: 'NavbarZones',
  components: {
    HomeIcon,
    ShieldCheckIcon,
    FilterIcon,
    CogIcon,
  },
};
</script>
