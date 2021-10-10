<template>
  <div class="page page-center">
    <div class="container-tight py-4">
      <div class="text-center mb-4">
        <h1>LightPath CDN</h1>
      </div>
      <Form class="card card-md" @submit="onSubmit" :validation-schema="schema">
        <div class="card-body">
          <h2 class="card-title text-center mb-4">Sign in to your account</h2>
          <div class="mb-3">
            <form-label>Username</form-label>
            <form-input
              name="username"
              placeholder="Enter your username"
              :disabled="!ready"
            />
          </div>
          <div class="mb-2">
            <form-label>Password</form-label>
            <form-input
              name="password"
              type="password"
              placeholder="Password"
              :disabled="!ready"
            />
          </div>
          <div class="form-footer">
            <button
              class="btn btn-primary w-100"
              :class="{ 'btn-loading': !ready }"
              type="submit"
            >
              Sign in
            </button>
          </div>
        </div>
      </Form>
    </div>
  </div>
</template>

<script>
import { Form } from 'vee-validate';
import { object, string } from 'yup';

import FormLabel from '../../components/Form/FormLabel';
import FormInput from '../../components/Form/FormInput';

export default {
  name: 'Login',
  components: {
    Form,
    FormLabel,
    FormInput,
  },
  setup() {
    const schema = object({
      username: string().required(),
      password: string().required(),
    });

    return { schema };
  },
  data: () => ({
    ready: true,
  }),
  methods: {
    async onSubmit(values, { setErrors }) {
      try {
        this.ready = false;
        await this.$store.dispatch('users/LOGIN', values);
        await this.$router.push({ name: 'ZonesOverview' });
      } catch (error) {
        if (error?.response.data.errors.message) {
          setErrors({
            username: error.response.data.errors.message,
            password: ' ',
          });
        }
      } finally {
        this.ready = true;
      }
    },
  },
};
</script>
