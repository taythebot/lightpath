import { createStore } from 'vuex';

// Modules
import users from './modules/users';
import zones from './modules/zones';

export default createStore({
  modules: { users, zones },
});
