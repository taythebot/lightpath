'use strict';

const Joi = require('../../utils/joi');

const zone = {
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
};

module.exports = {
  new: {
    body: Joi.object({
      domain: Joi.string().domain().required(),
      origin: Joi.string().domain().required(),
      enforce_https: Joi.boolean().required(),
      ssl_auto: Joi.boolean().required(),
      ssl_certificate: Joi.when('enforce_https', {
        is: Joi.valid(true),
        then: Joi.when('ssl_auto', {
          is: Joi.valid(true),
          then: Joi.string().max(100).required(),
          otherwise: Joi.optional().default(null),
        }),
        otherwise: Joi.optional().default(null),
      }),
      ssl_private_key: Joi.when('enforce_https', {
        is: Joi.valid(true),
        then: Joi.when('ssl_auto', {
          is: Joi.valid(true),
          then: Joi.string().max(100).required(),
          otherwise: Joi.optional().default(null),
        }),
        otherwise: Joi.optional().default(null),
      }),
      security_waf: Joi.boolean().required(),
      security_crawlers: Joi.boolean().required(),
    }),
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          message: { type: 'string' },
          zone,
        },
      },
    },
  },
  getAll: {
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          zones: { type: 'array', items: zone },
        },
      },
    },
  },
};
