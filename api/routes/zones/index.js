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

  // Validate zone options
  fastify.post('/validate', { schema: schemas.validate }, async (req, _) => {
    await zoneService.validateDomain({ domain: req.body.domain });
    return { message: 'zone create options are valid' };
  });

  // Get all zones by user
  fastify.get('/', { schema: schemas.getAll }, async (req, _) => {
    const { id } = req.requestContext.get('user');
    const results = await zoneService.getAll({ ...req.params, userId: id });
    return { message: 'zone successfully created', ...results };
  });

  // Get zone by ID
  fastify.get(
    '/:id',
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
