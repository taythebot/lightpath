<template>
  <Field
    v-model="currentValue"
    v-slot="{ errorMessage, field }"
    :name="name"
    as="div"
  >
    <textarea
      v-bind="field"
      :class="{ [inputClass]: true, 'is-invalid': errorMessage }"
      :placeholder="placeholder"
      :rows="rows"
      :disabled="disabled"
    />
    <form-error v-if="!slim && errorMessage" class="mt-1">
      {{ errorMessage }}
    </form-error>
  </Field>
</template>

<script>
import { Field } from 'vee-validate';

import FormError from './FormError';

export default {
  name: 'FormTextarea',
  components: {
    Field,
    FormError,
  },
  props: {
    modelValue: {
      type: String,
      default: null,
    },
    inputClass: {
      type: String,
      default: 'form-control',
    },
    name: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      default: null,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    rows: {
      type: Number,
      default: 3,
    },
    slim: {
      type: Boolean,
      default: false,
    },
  },
  data: () => ({
    currentValue: '',
  }),
  watch: {
    currentValue(val) {
      this.$emit('update:modelValue', val);
    },
  },
  mounted() {
    if (this.modelValue) {
      this.currentValue = this.modelValue;
    }
  },
};
</script>
