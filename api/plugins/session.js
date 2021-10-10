'use strict';

const fp = require('fastify-plugin');
const session = require('fastify-secure-session');

module.exports = fp(
  async (fastify) => {
    fastify.register(session, {
      cookieName: 'session',
      key: Buffer.from(process.env.SESSION_SECRET, 'hex'),
      cookie: { path: '/', httpOnly: process.env.NODE_ENV === 'production' },
    });
  },
  { fastify: '3.x', name: 'plugin-session' }
);