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
            >
              <template #[`item.domain`]="{ item: { id, domain } }">
                <router-link
                  class="text-reset font-weight-medium"
                  :to="{ name: 'ZonesAnalytics', params: { id } }"
                >
                  {{ domain }}
                </router-link>
              </template>
              <template #[`item.cache_enabled`]="{ item: { cache_enabled } }">
                {{ cache_enabled ? 'Enabled' : 'Disabled' }}
              </template>
              <template #[`item.security_waf`]="{ item: { security_waf } }">
                {{ security_waf ? 'Enabled' : 'Disabled' }}
              </template>
              <template #[`item.status`]="{ item: { status } }">
                <span class="badge bg-success me-1" />
                {{ status }}
              </template>
              <template #[`item.created_at`]="{ item: { created_at } }">
                {{ formatISO(created_at) }}
              </template>
              <template #noResults>
                <div class="empty p-4">
                  <p class="empty-title">No Zones Found</p>
                  <p class="empty-subtitle text-muted">
                    There are no zones on your account<br />Click the button
                    below to add a new site
                  </p>
                  <div class="empty-action mt-2">
                    <router-link
                      class="btn btn-primary"
                      :to="{ name: 'ZonesNew' }"
                    >
                      Add New Site
                    </router-link>
                  </div>
                </div>
              </template>
            </data-table>
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
      { value: 'cache_enabled', text: 'Cache' },
      { value: 'security_waf', text: 'WAF' },
      { value: 'status', text: 'Status', class: 'text-capitalize' },
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
