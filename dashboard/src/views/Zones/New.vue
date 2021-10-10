<template>
  <div class="page">
    <div class="container-tight py-4">
      <div class="card card-md">
        <div class="card-body text-center py-4 p-sm-5">
          <h1>Welcome to LightPath</h1>
          <p class="text-muted">
            LightPath makes it easy for you to operate your own CDN. Enter your
            site details below to continue.
          </p>
        </div>
        <div class="hr-text hr-text-center hr-text-spaceless">
          {{ currentTitle }}
        </div>
        <div class="card-body">
          <setup-step-one v-if="currentStep === 1" />
          <setup-step-two v-else-if="currentStep === 2" />
          <setup-step-three v-else-if="currentStep === 3" />
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
              to="/zone/new"
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
              type="button"
              @click="nextStep"
            >
              Continue
            </button>
            <button
              v-else
              class="btn btn-primary"
              type="button"
              @click="nextStep"
            >
              Submit
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SetupStepOne from "../../components/Setup/SetupStepOne";
import SetupStepTwo from "../../components/Setup/SetupStepTwo";
import SetupStepThree from "../../components/Setup/SetupStepThree";

export default {
  name: "ZoneNew",
  components: {
    SetupStepOne,
    SetupStepTwo,
    SetupStepThree,
  },
  setup() {
    const titles = [
      "Site Details",
      "SSL Configuration",
      "Security Configuration",
    ];
    return { titles };
  },
  data: () => ({
    currentStep: 1,
    maxStep: 3,
  }),
  computed: {
    currentTitle() {
      return this.titles[this.currentStep - 1];
    },
    currentProgress() {
      return Math.ceil((this.currentStep / this.maxStep) * 100);
    },
  },
  methods: {
    prevStep() {
      this.currentStep--;
    },
    nextStep() {
      this.currentStep++;
    },
  },
};
</script>
