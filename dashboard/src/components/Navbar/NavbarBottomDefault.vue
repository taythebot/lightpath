<template>
  <div class="navbar-expand-md">
    <div class="collapse navbar-collapse" id="navbar-menu">
      <div class="navbar navbar-light">
        <div class="container-xl">
          <ul class="navbar-nav">
            <li class="nav-item active">
              <a class="nav-link" href="./index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <globe-alt-icon />
                </span>
                <span class="nav-link-title">Zones</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./docs/index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <server-icon />
                </span>
                <span class="nav-link-title">Edge Servers</span>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="./docs/index.html">
                <span class="nav-link-icon d-md-none d-lg-inline-block">
                  <user-group-icon />
                </span>
                <span class="nav-link-title">Users</span>
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
  GlobeAltIcon,
  ServerIcon,
  UserGroupIcon,
  CogIcon,
} from '@heroicons/vue/outline';

export default {
  name: 'NavbarDefault',
  components: {
    GlobeAltIcon,
    ServerIcon,
    UserGroupIcon,
    CogIcon,
  },
};
</script>
