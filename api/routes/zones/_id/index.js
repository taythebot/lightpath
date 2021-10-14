'use strict';

const ZoneService = require('../../../services/zone');
const schemas = require('./schemas');

module.exports = async (fastify, _) => {
  const zoneService = new ZoneService(fastify);

  // Get zone by ID
  fastify.get(
    '/',
    {
      schema: schemas.get,
      config: {
        errors: { params: { status: 404, message: 'zone not found' } },
      },
    },
    async (req, _) => {
      const { id } = req.requestContext.get('user');
      const zone = await zoneService.get({ id: req.params.id, userId: id });
      return { zone };
    }
  );
};
