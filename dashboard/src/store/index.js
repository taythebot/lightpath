import { createStore } from 'vuex';

import users from './modules/users';

export default createStore({
  modules: { users },
});
