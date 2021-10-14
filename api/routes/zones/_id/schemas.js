'use strict';

const Joi = require('../../../utils/joi');

const params = Joi.object({
  id: Joi.string().length(32).required(),
});

module.exports = {
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
  getCache: {
    params,
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          cache: {
            type: 'object',
            properties: {
              cache_enabled: { type: 'boolean' },
              cache_ttl: { type: ['number', 'string'] },
              cache_query: { type: 'boolean' },
              cache_cookie: { type: 'boolean' },
            },
          },
        },
      },
    },
  },
  putCache: {
    params,
    body: Joi.object({
      cache_ttl: Joi.string().valid('Bypass', 'Origin'),
      cache_query: Joi.boolean(),
      cache_cookie: Joi.boolean(),
    }).min(1),
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
};
