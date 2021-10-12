<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Enable Edge SSL</h3>
        </div>
        <div class="card-body">
          <p>
            Terminate SSL on edge servers. This allows your websites to use
            HTTPS without the origin server supporting it
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
          <h3 class="card-title">Enforce HTTPS</h3>
        </div>
        <div class="card-body">
          <p>Redirect all HTTP requests to HTTPS</p>
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
          <h3 class="card-title">Automatic SSL</h3>
        </div>
        <div class="card-body">
          <p>Automatically generate Let's Encrypt SSL certificates</p>
          <p class="text-warning">This does not work with CNAME records</p>
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
          <h3 class="card-title">Custom SSL Certificate</h3>
        </div>
        <div class="card-body">
          <p>
            Add
            <kbd class="text-dark bg-light">Access-Control-Allow-Origin: *</kbd>
            headers to all responses
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
  name: 'ZonesSSL',
};
</script>
