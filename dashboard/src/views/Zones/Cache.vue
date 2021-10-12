<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Purge Edge Cache</h3>
        </div>
        <div class="card-body">
          <p>Purge specific items from the edge cache by specifying paths</p>
          <p class="mb-1">Wildcard paths are supported for purging</p>
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

    <div class="col-12 col-md-5">
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
            cache and proxy requests
          </p>
          <p class="mt-0">
            <span class="font-weight-medium">Respect Origin Headers</span> - Use
            existing cache-control headers
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

    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Sorted Query String</h3>
        </div>
        <div class="card-body">
          <p>
            Sort query strings alphabetically, allowing files with different
            order of query strings to be treated the same
          </p>
          <p>Enabling this will help increase cache HIT rates</p>
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

    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Strip Cookies</h3>
        </div>
        <div class="card-body">
          <p>Removes the set-cookie header from origin server</p>
          <p class="text-warning">
            Enabling this will break cookie based sessions
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
  </div>
</template>

<script>
export default {
  name: 'ZonesCache',
};
</script>
