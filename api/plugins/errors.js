'use strict';

const fp = require('fastify-plugin');
const statuses = require('statuses');

// Internal error codes
const codes = {
  ValidationError: {
    status: 400,
    code: 1000,
  },
  AuthRequired: {
    status: 403,
    code: 1001,
    message: 'authentication required',
  },
};

const parseMessage = (message) => {
  if (Array.isArray(message)) {
    return message.reduce(
      (obj, curr) => ({ ...obj, [curr.path[0]]: curr.message }),
      {}
    );
  } else {
    return message;
  }
};

module.exports = fp(
  async (fastify, _) => {
    // Make error plugins available to entire application
    fastify.decorate('error', ({ status, code, message }) => {
      const err = new Error();
      err.status = status;
      err.code = code;
      err.message = message;
      return err;
    });
    fastify.decorate('validationError', (message) => {
      const err = new Error();
      err.status = 400;
      err.code = 'ValidationError';
      err.message = message;
      return err;
    });

    // Not found handler
    fastify.setNotFoundHandler(() => {
      throw fastify.error({ status: 404 });
    });

    // Set custom error handler
    fastify.setErrorHandler((err, req, reply) => {
      let body = {};

      // Handle validation error
      if (err.code === 'ValidationError') {
        // Check for custom error override for route
        if (
          reply.context.config.errors &&
          reply.context.config.errors[err.location]
        ) {
          const override = reply.context.config.errors[err.location];
          body = {
            status: override.status,
            code: Number(`20${override.status}`),
            message: override.message ?? parseMessage(err.message),
          };
        } else {
          body = {
            status: err.status ?? codes.ValidationError.status,
            code: codes.ValidationError.code,
            message: parseMessage(err.message),
          };
        }
      } else {
        // Custom error from route config will always override everything else
        body = { ...(codes[err.name] ?? codes[err.code]) };

        if (Object.keys(body).length === 0) {
          // Set status from error
          const status = err.status || err.statusCode || 500;

          // Get default error message and override 5xx errors in production
          const message =
            process.env.NODE_ENV === 'production' && status >= 500
              ? statuses.message[status]
              : err.message ?? statuses.message[status];

          body = {
            status: status,
            code: message ? Number(`20${status}`) : null,
            message: message,
          };
        } else if (!body.message && err.message) {
          body.message = err.message;

          if (err.status) {
            body.status = err.status;
          }
        }
      }

      // Output to console if development or server error
      if (process.env.NODE_ENV === 'development' || body.status >= 500) {
        if (!err.message) {
          err.message = body.message;
        }
        req.log.error(err);
      }

      reply.code(body.status).send({ success: false, errors: body });
    });
  },
  { fastify: '3.x', name: 'plugin-errors' }
);
