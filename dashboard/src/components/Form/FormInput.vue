<template>
  <Field v-slot="{ errorMessage, field }" :name="name" as="div">
    <input
      v-bind="field"
      :class="{ [inputClass]: true, 'is-invalid': errorMessage }"
      :type="type"
      :placeholder="placeholder"
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
  name: 'FormInput',
  components: {
    Field,
    FormError,
  },
  props: {
    inputClass: {
      type: String,
      default: 'form-control',
    },
    type: {
      type: String,
      default: 'text',
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
    slim: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
