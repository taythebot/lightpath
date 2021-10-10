import services from '../../services';

const state = () => ({
  user: null,
});

const getters = {
  isAuthenticated: (state) => !!state.user,
  get: (state) => state.user,
};

const actions = {
  async GET({ commit }) {
    try {
      const { data } = await services.users.me();
      commit('LOGIN_SUCCESS', data.user);
      return data.user;
    } catch {
      return null;
    }
  },
  async LOGIN({ commit }, { username, password }) {
    const { data } = await services.users.login({ username, password });
    commit('LOGIN_SUCCESS', data.user);
  },
};

const mutations = {
  LOGIN_SUCCESS(state, user) {
    state.user = user;
  },
};

export default { namespaced: true, state, getters, actions, mutations };
