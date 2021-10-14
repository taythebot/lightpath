'use strict';

const Joi = require('../../utils/joi');

const params = Joi.object({
  id: Joi.string().length(32).required(),
});

const querystring = Joi.object({
  query: Joi.string().alphanum().length(16).escape().optional().default(null),
  limit: Joi.number().integer().greater(0).default(10),
  offset: Joi.number().integer().greater(0).allow(0).default(0),
  order: Joi.string().alphanum().escape().optional().default(null),
  dir: Joi.string().valid('asc', 'desc').optional().default(null),
});

module.exports = {
  new: {
    body: Joi.object({
      domain: Joi.string().domain().required(),
      origin: Joi.string()
        .uri({ scheme: ['http', 'https'] })
        .required(),
      enforce_https: Joi.boolean().required(),
      ssl_auto: Joi.boolean().required(),
      ssl_certificate: Joi.when('enforce_https', {
        is: Joi.valid(true),
        then: Joi.when('ssl_auto', {
          is: Joi.valid(false),
          then: Joi.string().max(100).required(),
          otherwise: Joi.optional().empty('').default(null),
        }),
        otherwise: Joi.optional().empty('').default(null),
      }),
      ssl_private_key: Joi.when('enforce_https', {
        is: Joi.valid(true),
        then: Joi.when('ssl_auto', {
          is: Joi.valid(false),
          then: Joi.string().max(100).required(),
          otherwise: Joi.optional().empty('').default(null),
        }),
        otherwise: Joi.optional().empty('').default(null),
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
          zone: { $ref: 'zone#' },
        },
      },
    },
  },
  validate: {
    body: Joi.object({
      domain: Joi.string().domain().required(),
      origin: Joi.string()
        .uri({ scheme: ['http', 'https'] })
        .required(),
    }),
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          message: { type: 'string' },
        },
      },
    },
  },
  getAll: {
    querystring,
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          metadata: {
            type: 'object',
            properties: {
              total: { type: 'number', default: 0 },
            },
          },
          zones: { type: 'array', items: { $ref: 'zone#' } },
        },
      },
    },
  },
  get: {
    params,
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          zone: { $ref: 'zone#' },
        },
      },
    },
  },
};
