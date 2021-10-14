<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Edge SSL Termination</h3>
        </div>
        <div class="card-body">
          <p>
            Terminate SSL on edge servers. Serve HTTPS requests without origin
            server support
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
          <p>Redirects all HTTP requests to HTTPS</p>
          <p class="text-blue">
            This can be disabled for specific paths via Edge Rules
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
          <h3 class="card-title">Automatic SSL Certificate</h3>
        </div>
        <div class="card-body">
          <p>Automatically generate a Let's Encrypt SSL certificate</p>
          <p class="text-blue">SSL certificates are automatically renewed</p>
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
          <p>Use your own SSL certificate on edge servers</p>
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
