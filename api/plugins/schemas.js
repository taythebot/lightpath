'use strict';

const fp = require('fastify-plugin');

// const Joi = require('../utils/joi');

module.exports = fp(
  async (fastify) => {
    // Fix joi shared schema
    // fastify.addSchema({
    //   $id: 'zoneId',
    //   schema: Joi.object({
    //     id: Joi.string().length(32).required(),
    //   }),
    // });

    fastify.addSchema({
      $id: 'zone',
      type: 'object',
      properties: {
        id: { type: 'string' },
        domain: { type: 'string' },
        origin: { type: 'string' },
        enforce_https: { type: 'boolean' },
        ssl_auto: { type: 'boolean' },
        cache_enabled: { type: 'boolean' },
        security_cors: { type: 'boolean' },
        security_waf: { type: 'boolean' },
        security_crawlers: { type: 'boolean' },
        status: { type: 'string' },
        created_at: { type: 'string', format: 'Date' },
        updated_at: { type: 'string', format: 'Date' },
      },
    });
  },
  { fastify: '3.x', name: 'plugin-schemas' }
);
