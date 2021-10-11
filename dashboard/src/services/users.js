export default (client) => ({
  login: ({ username, password }) =>
    client.post('/auth/login', { username, password }),
  logout: () => client.post('/auth/logout'),
  me: () => client.get('/users/me'),
});
