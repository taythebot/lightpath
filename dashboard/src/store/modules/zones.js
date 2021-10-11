const state = () => ({
  zones: [],
});

const getters = {
  getAll: (state) => state.zones,
  getById: (state) => (id) => state.zones.find((zone) => zone.id === id),
};

const actions = {
  // Fetch all zones by user
  async GET_ALL({ commit }) {
    const { data } = await this.$api.zones.getAll();
    commit('ADD_ZONES', data.zones);
  },
};

const mutations = {
  ADD_ZONES(state, zones) {
    for (const zone of zones) {
      const index = state.zones.findIndex((e) => e.id === zone.id);
      if (index !== -1) state.zones.splice(index, 1);

      state.zones.push(zone);
    }
  },
};

export default { namespaced: true, state, getters, actions, mutations };
