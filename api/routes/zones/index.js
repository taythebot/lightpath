'use strict';

const ZoneService = require('../../services/zone');
const schemas = require('./schemas');

module.exports = async (fastify, _) => {
  const zoneService = new ZoneService(fastify);

  // Create new zone
  fastify.post('/', { schema: schemas.new }, async (req, _) => {
    const { id } = req.requestContext.get('user');
    const zone = await zoneService.create({ body: req.body, userId: id });
    return { message: 'zone successfully created', zone };
  });

  // Get all zones by user
  fastify.get('/', { schema: schemas.getAll }, async (req, _) => {
    const { id } = req.requestContext.get('user');
    const zones = await zoneService.getAll({ userId: id });
    return { message: 'zone successfully created', zones };
  });
};
