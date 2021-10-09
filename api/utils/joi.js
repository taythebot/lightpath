'use strict'

const Joi = require('joi')

module.exports = Joi.extend((joi) => ({
  type: 'string',
  base: joi.string(),
  messages: {
    alpha: '{{#label}} must only contain letters',
  },
  rules: {
    // Require only letters
    alpha: {
      validate: (value, helpers) =>
        value.match(/^[a-z]+$/i) ? value : helpers.error('alpha'),
    },
    // Sanitize input
    escape: {
      validate: (value) =>
        value
          .replace(/&/g, '&amp;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&#x27;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/\//g, '&#x2F;')
          .replace(/\\/g, '&#x5C;')
          .replace(/`/g, '&#96;'),
    },
  },
}))
