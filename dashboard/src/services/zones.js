export default (client) => ({
  getAll: () => client.get('/zones'),
  new: (body) => client.post('/zones', body),
  validate: (body) => client.post('/zones/validate', body),
  get: (id) => client.get(`/zones/${id}`),
  getCacheSettings: (id) => client.get(`/zones/${id}/cache`),
  editCacheSettings: (id, body) => client.put(`/zones/${id}/cache`, body),
});
