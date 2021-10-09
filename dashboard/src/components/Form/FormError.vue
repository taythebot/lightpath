<template>
  <div class="invalid-feedback font-weight-medium">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'FormError',
};
</script>

<style scoped>
.invalid-feedback {
  font-size: 0.8rem;
}
</style>
