<template>
  <label class="form-check form-check-single form-switch">
    <input
      v-model="currentValue"
      :class="inputClass"
      type="checkbox"
      :disabled="disabled"
    />
  </label>
</template>

<script>
import { useField } from 'vee-validate';

export default {
  name: 'FormSwitch',
  props: {
    modelValue: {
      type: Boolean,
      default: false,
    },
    inputClass: {
      type: String,
      default: 'form-check-input',
    },
    type: {
      type: String,
      default: 'text',
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  setup(props) {
    const { checked, handleChange } = useField(props.name, undefined, {
      type: 'checkbox',
      valueProp: props.modelValue,
      initialValue: props.modelValue,
      uncheckedValue: false,
    });

    return { checked, handleChange };
  },
  data: () => ({
    currentValue: false,
  }),
  watch: {
    modelValue(val) {
      this.currentValue = val;
    },
    currentValue(val) {
      this.$emit('update:modelValue', val);
      this.handleChange(val);
    },
  },
  mounted() {
    this.currentValue = this.modelValue;
    this.handleChange(this.modelValue);
  },
};
</script>
