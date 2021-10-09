const state = () => ({
  session: null,
});

const getters = {
  isAuthenticated: (state) => !!state.session,
};

const actions = {};

const mutations = {};

export default { namespaced: true, state, getters, actions, mutations };
