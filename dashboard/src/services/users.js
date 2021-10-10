export default (client) => ({
  login: ({ username, password }) =>
    client.post('/auth/login', { username, password }),
  me: () => client.get('/users/me'),
});
