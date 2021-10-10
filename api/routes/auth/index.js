'use strict';

const AuthService = require('../../services/auth');
const schemas = require('./schemas');

module.exports = async (fastify, _) => {
  const authService = new AuthService(fastify);

  // Login
  fastify.post('/login', { schema: schemas.login }, async (req, _) => {
    const { id, username, role } = await authService.login(req.body);

    // Set session
    req.session.set('id', id);

    return { message: 'login successful', user: { username, role } };
  });

  // Logout
  fastify.post('/logout', { schema: schemas.logout }, async (req, _) => {
    req.session.delete();
    return { message: 'logout successful' };
  });
};
