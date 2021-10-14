<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-6">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Purge Edge Cache</h3>
        </div>
        <div class="card-body">
          <p>
            Clear items from edge cache forcing requests to be forwarded to the
            origin
          </p>
          <p class="mb-1">
            <span class="font-weight-medium">Custom Purge</span> - Purge
            specific items using URLs
          </p>
          <p>
            <span class="font-weight-medium">Purge All</span> - Purge all items
            in zone from edge cache
          </p>
        </div>
        <div class="card-footer d-flex justify-content-end space-x-2">
          <button class="btn btn-sm btn-primary">Custom Purge</button>
          <button class="btn btn-sm btn-primary">Purge All</button>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-6">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Edge Cache TTL</h3>
        </div>
        <div class="card-body">
          <p>
            The amount of time a cache item should be stored on an edge server
          </p>
          <p class="mb-1">
            <span class="font-weight-medium">Bypass Cache</span> - Bypass edge
            cache and pull from origin
          </p>
          <p>
            <span class="font-weight-medium">Respect Origin</span> - Use
            <kbd class="text-dark bg-light">cache-control</kbd> headers from
            origin
          </p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              class="form-check-input position-static"
              type="checkbox"
              checked=""
            />
          </label>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-6">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Sorted Query String</h3>
        </div>
        <div class="card-body">
          <p>
            Sort query strings alphabetically, allowing files with different
            query string orders to be treated the same
          </p>
        </div>
        <div class="card-footer d-flex justify-content-between">
          <div class="d-flex space-x-1">
            <information-circle-icon class="icon text-blue" />
            <p class="text-blue mb-0">Helps increase cache HIT rates</p>
          </div>
          <label class="form-check form-switch m-0 float-end">
            <input
              v-model="cache.cache_query"
              class="form-check-input position-static"
              type="checkbox"
              :disabled="!ready"
              @change="change('cache_query')"
            />
          </label>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-6">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Strip Cookies</h3>
        </div>
        <div class="card-body">
          <p>
            Removes the <kbd class="text-dark bg-light">set-cookie</kbd> header
            from origin server
          </p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              v-model="cache.cache_cookie"
              class="form-check-input position-static"
              type="checkbox"
              :disabled="!ready"
              @change="change('cache_cookie')"
            />
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { InformationCircleIcon } from '@heroicons/vue/solid';

export default {
  name: 'ZonesCache',
  props: {
    zone: {
      type: Object,
      required: true,
    },
  },
  components: {
    InformationCircleIcon,
  },
  data: () => ({
    ready: false,
    cache: {
      cache_ttl: 'Bypass',
      cache_query: false,
      cache_cookie: false,
    },
  }),
  methods: {
    async change(setting) {
      try {
        this.ready = false;
        await this.$api.zones.editCacheSettings(this.$route.params.id, {
          [setting]: this.cache[setting],
        });
      } catch (error) {
        console.error(error);
      } finally {
        this.ready = true;
      }
    },
  },
  async mounted() {
    const { data } = await this.$api.zones.getCacheSettings(
      this.$route.params.id
    );
    this.cache = data.cache;
    this.ready = true;
  },
};
</script>
