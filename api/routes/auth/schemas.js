'use strict';

const Joi = require('../../utils/joi');

module.exports = {
  login: {
    body: Joi.object({
      username: Joi.string().max(30).escape().required(),
      password: Joi.string().required(),
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
  logout: {
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
