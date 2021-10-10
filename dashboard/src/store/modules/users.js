import services from '../../services';

const state = () => ({
  user: null,
});

const getters = {
  isAuthenticated: (state) => !!state.user,
  get: (state) => state.user,
  getUsername: (state) => state.user?.username,
  getRole: (state) => state.user?.role,
};

const actions = {
  // Fetch user data
  async GET({ commit, dispatch }) {
    try {
      // Fetch user data
      const { data } = await services.user.me();
      commit('LOGIN_SUCCESS', data.user);

      // Get zones
      dispatch('zones/GET_ALL', null, { root: true });

      return data.user;
    } catch {
      return null;
    }
  },
  // Login user
  async LOGIN({ commit }, { username, password }) {
    const { data } = await services.user.login({ username, password });
    commit('LOGIN_SUCCESS', data.user);
  },
  // Logout user
  async LOGOUT({ commit }) {
    await services.users.logout();
    commit('LOGOUT');
  },
};

const mutations = {
  LOGIN_SUCCESS(state, user) {
    state.user = user;
  },
  LOGOUT(state) {
    state.user = null;
  },
};

export default { namespaced: true, state, getters, actions, mutations };
