'use strict';

const fp = require('fastify-plugin');

module.exports = fp(
  async (fastify, _) => {
    // Set custom validation handler
    fastify.setValidatorCompiler(({ schema, httpPart }) => (data) => {
      const { error, value } = schema.validate(data, {
        errors: {
          wrap: { label: null },
        },
        abortEarly: false,
        stripUnknown: true,
      });
      if (!error) {
        return { value };
      }

      // Create Error
      const err = new Error();
      err.status = 400;
      err.code = 'ValidationError';

      // Inject where error occurred
      err.message = error.details;
      err.location = httpPart;

      // Return error
      return { error: err };
    });
  },
  { fastify: '3.x', name: 'plugin-validator', dependencies: ['plugin-errors'] }
);
