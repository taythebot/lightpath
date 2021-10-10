'use strict';

const fp = require('fastify-plugin');
const { fastifyRequestContextPlugin } = require('fastify-request-context');

const whitelist = ['/v1/auth/login'];

module.exports = fp(
  async (fastify) => {
    fastify.register(fastifyRequestContextPlugin);

    // Authentication middleware
    fastify.addHook('onRequest', async (req, _) => {
      // Get user ID from session
      const id = req.session.get('id');

      // Check for whitelist
      const isWhitelist = whitelist.includes(req.routerPath);
      if (isWhitelist) return;
      else if (!id) throw fastify.error({ code: 'AuthRequired' });

      // Verify session
      const user = await fastify.sequelize.users.findByPk(id, {
        attributes: ['id', 'username', 'role'],
      });
      if (!user) {
        req.session.delete();
        throw fastify.error({ code: 'AuthRequired' });
      }

      // Set user context
      req.requestContext.set('user', user);
    });
  },
  {
    fastify: '3.x',
    name: 'plugin-auth',
    dependencies: ['plugin-sequelize', 'plugin-session', 'plugin-errors'],
  }
);
