<template>
  <div class="space-y-4">
    <div class="row">
      <div class="col">
        <label class="form-label mb-0">Enforce HTTPS</label>
        <span class="form-check-description">
          Redirects all HTTP requests to HTTPS
        </span>
      </div>
      <div class="col-auto my-auto">
        <label class="form-check form-check-single form-switch">
          <input
            v-model="enforceSSL"
            class="form-check-input"
            type="checkbox"
          />
        </label>
      </div>
    </div>
    <div class="row">
      <div class="col">
        <label class="form-label mb-0">Automatic SSL</label>
        <span class="form-check-description">
          Automatically generate a Let's Encrypt SSL certificate
        </span>
      </div>
      <div class="col-auto my-auto">
        <label class="form-check form-check-single form-switch">
          <input
            v-model="autoSSL"
            class="form-check-input"
            type="checkbox"
            :disabled="!enforceSSL"
          />
        </label>
      </div>
    </div>
    <template v-if="enforceSSL && !autoSSL">
      <div>
        <label class="form-label">Custom SSL Certificate</label>
        <textarea class="form-control" rows="3" />
      </div>
      <div>
        <label class="form-label">Custom SSL Private Key</label>
        <textarea class="form-control" rows="3" />
      </div>
    </template>
  </div>
</template>

<script>
export default {
  name: "SetupStepTwo",
  data: () => ({
    enforceSSL: true,
    autoSSL: true,
  }),
};
</script>
