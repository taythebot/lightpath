<template>
  <div class="space-y-4">
    <div class="row">
      <div class="col">
        <label class="form-label mb-0">Enable WAF</label>
        <span class="form-check-description">
          Enables Web Application Firewall with ModSecurity Core Rule Set
        </span>
      </div>
      <div class="col-auto my-auto">
        <label class="form-check form-check-single form-switch">
          <input class="form-check-input" type="checkbox" checked="" />
        </label>
      </div>
    </div>
    <div class="row">
      <div class="col">
        <label class="form-label mb-0">Allow Crawlers</label>
        <span class="form-check-description">
          Allow known crawlers to access your site without triggering security
          rules
        </span>
      </div>
      <div class="col-auto my-auto">
        <label class="form-check form-check-single form-switch">
          <input class="form-check-input" type="checkbox" checked="" />
        </label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "SetupStepThree",
};
</script>

<style scoped></style>
