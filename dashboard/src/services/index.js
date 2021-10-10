import axios from 'axios';

// Services
import UserService from './user';

// Create axios client
const client = axios.create({
  baseURL: process.env.VUE_APP_API,
  withCredentials: true,
});

export default {
  user: UserService(client),
};
