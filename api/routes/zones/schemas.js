'use strict';

const Joi = require('../../utils/joi');

module.exports = {
  new: {
    body: Joi.object({
      domain: Joi.string().domain().required(),
      origin: Joi.string().domain().required(),
    }),
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          message: { type: 'string' },
          user: {
            type: 'object',
            properties: {
              username: { type: 'string' },
              role: { type: 'string' },
            },
          },
        },
      },
    },
  },
};
