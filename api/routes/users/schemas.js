'use strict'

const Joi = require('../../utils/joi')

const user = {
  type: 'object',
  properties: {
    id: { type: 'number' },
    username: { type: 'string' },
    updated_at: { type: 'string', format: 'Date' },
    created_at: { type: 'string', format: 'Date' },
  },
}

module.exports = {
  getAll: {
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          users: { type: 'array', items: user },
        },
      },
    },
  },
  getUser: {
    params: Joi.object({
      username: Joi.string().max(10).escape().required(),
    }),
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean', default: true },
          user,
        },
      },
    },
  },
}
