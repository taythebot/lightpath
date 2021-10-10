import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';

// Custom css
import './assets/css/tabler.css';
import './assets/css/main.css';

// Create vue app
const app = createApp(App);

// Filters
app.config.globalProperties.$filters = {
  capitalize(value) {
    if (!value) return '';
    value = value.toString();
    return value.charAt(0).toUpperCase() + value.slice(1);
  },
};

// Mount app
app.use(store).use(router).mount('#app');
