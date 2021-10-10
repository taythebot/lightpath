import axios from 'axios';

// Services
import UserService from './user';
import ZoneService from './zone';

// Create axios client
const client = axios.create({
  baseURL: process.env.VUE_APP_API,
  withCredentials: true,
});

export default {
  user: UserService(client),
  zone: ZoneService(client),
};
