'use strict';

const fp = require('fastify-plugin');
const cors = require('fastify-cors');

module.exports = fp(
  async (fastify) => {
    fastify.register(cors, {
      origin:
        process.env.NODE_ENV === 'development' ? true : process.env.DOMAIN,
      methods: ['GET', 'PUT', 'POST'],
      allowedHeaders: ['Content-Type'],
      credentials: true,
    });
  },
  { fastify: '3.x', name: 'plugin-cors' }
);
