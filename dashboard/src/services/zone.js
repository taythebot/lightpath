export default (client) => ({
  getAll: () => client.get('/zones'),
  new: (body) => client.post('/zones', body),
});
