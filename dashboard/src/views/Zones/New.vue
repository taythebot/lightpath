<template>
  <div class="page">
    <div class="container-tight py-4">
      <Form @submit="onSubmit" :validation-schema="currentSchema">
        <div class="card card-md">
          <div class="card-body text-center py-4 p-sm-5">
            <h1>Welcome to LightPath</h1>
            <p class="text-muted">
              LightPath makes it easy for you to operate your own CDN. Enter
              your site details below to continue.
            </p>
          </div>
          <div class="hr-text hr-text-center hr-text-spaceless">
            {{ currentTitle }}
          </div>
          <div class="card-body space-y-3">
            <template v-if="currentStep === 1">
              <div>
                <form-label>Domain</form-label>
                <form-input
                  v-model="form.domain"
                  name="domain"
                  placeholder="lightpath.io"
                  :disabled="!ready"
                />
                <div class="mt-2 form-hint">
                  Subdomains are supported but cannot be a wildcard
                </div>
              </div>
              <div>
                <form-label>Origin URL</form-label>
                <form-input
                  v-model="form.origin"
                  name="origin"
                  placeholder="https://1.2.3.4:8080"
                  :disabled="!ready"
                />
                <div class="mt-2 form-hint">
                  Enter the URL of the origin you wish to proxy traffic to. Load
                  balancing can be enabled after setup
                </div>
              </div>
            </template>
            <template v-else-if="currentStep === 2">
              <div class="row">
                <div class="col">
                  <form-label class="mb-0">Enforce HTTPS</form-label>
                  <span class="form-check-description">
                    Redirects all HTTP requests to HTTPS
                  </span>
                </div>
                <div class="col-auto my-auto">
                  <form-switch
                    v-model="form.enforce_https"
                    name="enforce_https"
                    :disabled="!ready"
                  />
                </div>
              </div>
              <div class="row">
                <div class="col">
                  <form-label class="mb-0">Automatic SSL</form-label>
                  <span class="form-check-description">
                    Automatically generate a Let's Encrypt SSL certificate
                  </span>
                </div>
                <div class="col-auto my-auto">
                  <form-switch
                    v-model="form.ssl_auto"
                    name="ssl_auto"
                    :disabled="!ready"
                  />
                </div>
              </div>
              <template v-if="form.enforce_https && !form.ssl_auto">
                <div>
                  <form-label>Custom SSL Certificate</form-label>
                  <form-textarea
                    v-model="form.ssl_certificate"
                    name="ssl_certificate"
                    :disabled="!ready"
                  />
                </div>
                <div>
                  <form-label>Custom SSL Private Key</form-label>
                  <form-textarea
                    v-model="form.ssl_private_key"
                    name="ssl_private_key"
                    :disabled="!ready"
                  />
                </div>
              </template>
            </template>
            <template v-else-if="currentStep === 3">
              <div class="row">
                <div class="col">
                  <form-label class="mb-0">Enable WAF</form-label>
                  <span class="form-check-description">
                    Enables Web Application Firewall with ModSecurity Core Rule
                    Set
                  </span>
                </div>
                <div class="col-auto my-auto">
                  <form-switch
                    v-model="form.security_waf"
                    name="security_waf"
                    :disabled="!ready"
                  />
                </div>
              </div>
              <div class="row">
                <div class="col">
                  <form-label class="mb-0">Allow Crawlers</form-label>
                  <span class="form-check-description">
                    Allow known crawlers to access your site without triggering
                    security rules
                  </span>
                </div>
                <div class="col-auto my-auto">
                  <form-switch
                    v-model="form.security_crawlers"
                    name="security_crawlers"
                    :disabled="!ready"
                  />
                </div>
              </div>
            </template>
          </div>
        </div>
        <div class="row align-items-center mt-3">
          <div class="col-4">
            <div class="progress">
              <div
                class="progress-bar"
                :style="`width: ${currentProgress}%`"
                role="progressbar"
                :aria-valuenow="currentProgress"
                aria-valuemin="0"
                aria-valuemax="100"
              >
                <span class="visually-hidden">
                  {{ currentProgress }}% Complete
                </span>
              </div>
            </div>
          </div>
          <div class="col">
            <div class="btn-list justify-content-end">
              <router-link
                v-if="currentStep === 1"
                class="btn btn-link link-secondary"
                to="/"
              >
                Cancel
              </router-link>
              <button
                v-else
                class="btn btn-link link-secondary"
                type="button"
                @click="prevStep"
              >
                Previous Step
              </button>
              <button
                v-if="currentStep !== maxStep"
                class="btn btn-primary"
                :class="{ 'btn-loading': !ready }"
                type="submit"
              >
                Continue
              </button>
              <button
                v-else
                class="btn btn-primary"
                :class="{ 'btn-loading': !ready }"
                type="submit"
              >
                Submit
              </button>
            </div>
          </div>
        </div>
      </Form>
    </div>
  </div>
</template>

<script>
import { Form } from 'vee-validate';
import { object, string, boolean } from 'yup';

import FormLabel from '../../components/Form/FormLabel';
import FormInput from '../../components/Form/FormInput';
import FormSwitch from '../../components/Form/FormSwitch';
import FormTextarea from '../../components/Form/FormTextarea';

export default {
  name: 'ZoneNew',
  components: {
    Form,
    FormLabel,
    FormInput,
    FormSwitch,
    FormTextarea,
  },
  setup() {
    const titles = [
      'Site Details',
      'SSL Configuration',
      'Security Configuration',
    ];
    const schemas = [
      object({
        domain: string().required(),
        origin: string().required(),
      }),
      object({
        enforce_https: boolean().required(),
        ssl_auto: boolean().required(),
        ssl_certificate: string(),
        ssl_private_key: string(),
      }),
      object({
        security_waf: boolean().required(),
        security_crawlers: boolean().required(),
      }),
    ];

    return { titles, schemas };
  },
  data: () => ({
    ready: true,
    currentStep: 1,
    maxStep: 3,
    form: {
      domain: '',
      origin: '',
      enforce_https: true,
      ssl_auto: true,
      ssl_certificate: '',
      ssl_private_key: '',
      security_waf: true,
      security_crawlers: true,
    },
  }),
  computed: {
    currentTitle() {
      return this.titles[this.currentStep - 1];
    },
    currentProgress() {
      return Math.ceil((this.currentStep / this.maxStep) * 100);
    },
    currentSchema() {
      return this.schemas[this.currentStep - 1];
    },
  },
  methods: {
    prevStep() {
      this.currentStep--;
    },
    async onSubmit(values, { setErrors }) {
      try {
        this.ready = false;

        // Validate domain and origin
        if (this.currentStep === 1) {
          await this.$api.zones.validate(values);
        }

        // Increment step
        if (this.currentStep < this.maxStep) {
          return this.currentStep++;
        }

        // Create zone
        const id = await this.$store.dispatch('zones/NEW', this.form);

        // Redirect
        await this.$router.push({ name: 'ZonesAnalytics', params: { id } });
      } catch (error) {
        console.log(error);
        if (error?.response.data.errors.message) {
          setErrors(error.response.data.errors.message);
        }
      } finally {
        this.ready = true;
      }
    },
  },
};
</script>
