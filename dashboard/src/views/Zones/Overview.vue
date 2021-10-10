<template>
  <div class="page-wrapper">
    <div class="container-xl">
      <div class="page-header d-print-none">
        <div class="row align-items-center">
          <div class="col">
            <div class="page-pretitle">Overview</div>
            <h2 class="page-title">Zones Overview</h2>
          </div>
        </div>
      </div>
    </div>
    <div class="page-body">
      <div class="container-xl">
        <div class="row row-deck row-cards">
          <div class="col-12">
            <data-table
              title="All Zones"
              :headers="headers"
              :server="server"
              :pagination="true"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import DataTable from '../../components/DataTable/DataTable';

export default {
  name: 'ZonesOverview',
  components: {
    DataTable,
  },
  data: () => ({
    headers: [
      { value: 'domain', text: 'Domain' },
      { value: 'origin', text: 'Origin' },
      { value: 'created_at', text: 'Created At' },
    ],
  }),
  computed: {
    server() {
      return {
        url: '/zones',
        then: (data) => data.zones,
        total: (data) => data.metadata.total,
      };
    },
  },
};
</script>
