import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';

// Custom css
import './assets/css/tabler.css';
import './assets/css/main.css';

// Create vue app
createApp(App).use(store).use(router).mount('#app');
