<template>
  <div class="space-y-4">
    <div>
      <label class="form-label">Domain</label>
      <div class="input-group input-group-flat">
        <span class="input-group-text"> https://</span>
        <input class="form-control ps-1" type="text" autocomplete="off" />
      </div>
    </div>
    <div>
      <label class="form-label">Backend IP Address</label>
      <input class="form-control" type="text" autocomplete="off" />
      <div class="form-hint">
        Enter the IP address of the server you wish to proxy traffic to. Load
        balancing can be enabled after setup
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "SetupStepOne",
};
</script>
