import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';

// Custom plugins
import services from './plugins/services';
import luxon from './plugins/luxon';

// Custom css
import './assets/css/tabler.css';
import './assets/css/main.css';

// Create vue app
const app = createApp(App)
  .use(store)
  .use(router)
  .use(services, { baseURL: process.env.VUE_APP_API })
  .use(luxon)
  .mount('#app');

// Make axios and services available to Vuex
store.$axios = app.$axios;
store.$api = app.$api;

export default app;
