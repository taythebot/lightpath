'use strict';

const fp = require('fastify-plugin');
const Redis = require('ioredis');

module.exports = fp(
  async (fastify) => {
    // Start new Redis instance
    const redis = new Redis(process.env.REDIS);

    // Make Redis available globally
    fastify.decorate('redis', redis);

    // Close Redis connection
    fastify.addHook('onClose', async () => await redis.quit());

    // Sync zone configuration to Redis
    fastify.decorate(
      'syncZone',
      async (id) => {
        // Get zone settings
        const zone = await fastify.sequelize.zones.findByPk(id, { raw: true });
        if (!zone) throw new Error('Zone not found');

        // Do not sync dates and user_id
        delete zone.user_id;
        delete zone.created_at;
        delete zone.updated_at;

        // Sync to Redis
        await redis.hmset(id, zone);
      },
      ['redis', 'sequelize']
    );
  },
  { fastify: '3.x', name: 'plugin-redis', dependencies: ['plugin-sequelize'] }
);
