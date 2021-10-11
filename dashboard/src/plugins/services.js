import axios from 'axios';
import services from '../services';

export default {
  install: (app, { baseURL }) => {
    const client = axios.create({ baseURL, withCredentials: true });
    app.config.globalProperties.$axios = client;
    app.config.globalProperties.$api = services(client);
  },
};
