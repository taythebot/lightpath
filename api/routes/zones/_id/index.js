'use strict';

const ZoneService = require('../../../services/zone');
const schemas = require('./schemas');

module.exports = async (fastify, _) => {
  const zoneService = new ZoneService(fastify);

  // Zone middleware
  fastify.addHook('preHandler', async (req, _) => {
    const { id } = req.requestContext.get('user');
    const zone = await zoneService.middleware({
      id: req.params.id,
      userId: id,
    });
    req.requestContext.set('zone', zone);
  });

  // Get zone
  fastify.get(
    '/',
    {
      schema: schemas.get,
      config: {
        errors: { params: { status: 404, message: 'zone not found' } },
      },
    },
    async (req, _) => {
      return { zone: req.requestContext.get('zone') };
    }
  );

  // Get cache settings
  fastify.get(
    '/cache',
    {
      schema: schemas.getCache,
      config: {
        errors: { params: { status: 404, message: 'zone not found' } },
      },
    },
    async (req, _) => {
      const { id } = req.requestContext.get('zone');
      const cache = await zoneService.getCacheSettings({ id });
      return { cache };
    }
  );

  // Edit cache settings
  fastify.put(
    '/cache',
    {
      schema: schemas.putCache,
      config: {
        errors: { params: { status: 404, message: 'zone not found' } },
      },
    },
    async (req, _) => {
      const { id } = req.requestContext.get('zone');
      await zoneService.updateSettings({ id, body: req.body });
      return { message: 'zone cache settings successfully updated' };
    }
  );
};
