'use strict';

const ZoneService = require('../../services/zone');
const schemas = require('./schemas');

module.exports = async (fastify, _) => {
  const zoneService = new ZoneService(fastify);

  // Create new zone
  fastify.post('/', { schema: schemas.new }, async (req, _) => {
    const { id, username, role } = await zoneService.new(req.body);

    // Set session
    req.session.set('id', id);

    return { message: 'login successful', user: { username, role } };
  });
};
