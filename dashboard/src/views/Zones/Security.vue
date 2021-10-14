<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Web Application Firewall</h3>
        </div>
        <div class="card-body">
          <p>
            Enable web application firewall to block malicious requests using
            ModSecurity Core Ruleset
          </p>
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
          <h3 class="card-title">Captcha</h3>
        </div>
        <div class="card-body">
          <p>Require all visitors to solve a Captcha to access your website</p>
          <p>Support Providers: Geetest, hCaptcha, Recaptcha</p>
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
          <h3 class="card-title">Javascript Bot Verification</h3>
        </div>
        <div class="card-body">
          <p>
            Require all visitors to pass a Javascript based bot verification to
            access your website
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
          <h3 class="card-title">Allow Crawlers</h3>
        </div>
        <div class="card-body">
          <p>
            Allow commonly known search engine crawlers to index your website
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
          <h3 class="card-title">Enable CORS Headers</h3>
        </div>
        <div class="card-body">
          <p>
            Add
            <kbd class="text-dark bg-light">Access-Control-Allow-Origin: *</kbd>
            header to all responses
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
  name: 'ZonesSecurity',
};
</script>
