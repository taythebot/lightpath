import axios from 'axios';

// Services
import UserService from './users';

// Create axios client
const client = axios.create({
  baseURL: process.env.VUE_APP_API,
  withCredentials: true,
});

export default {
  users: UserService(client),
};
