<template>
  <div class="page-wrapper">
    <div class="container-xl">
      <div class="page-header d-print-none">
        <div class="row align-items-center">
          <div class="col">
            <div class="page-pretitle">test.com</div>
            <h2 class="page-title">
              {{ $route.name.split('Zones')[1] }}
            </h2>
          </div>
        </div>
      </div>
    </div>
    <div class="page-body">
      <div class="container-xl">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ZoneRoot',
};
</script>
