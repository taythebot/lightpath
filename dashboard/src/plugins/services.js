import Services from '../services';
import axios from 'axios';

export default {
  install: (app, { baseURL }) => {
    const client = axios.create({ baseURL, withCredentials: true });
    const services = Services(client);

    // app.provide('$axios', client);
    // app.provide('$api', services(client));

    // Make plugins available globally
    app.config.globalProperties.$axios = client;
    app.config.globalProperties.$api = services;
  },
};
