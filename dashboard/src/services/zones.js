export default (client) => ({
  getAll: () => client.get('/zones'),
  new: (body) => client.post('/zones', body),
  validate: (body) => client.post('/zones/validate', body),
});
