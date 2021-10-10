'use strict';

const crypto = require('crypto');

module.exports = class ZoneService {
  /**
   * Creates new instance of ZoneService
   * @param fastify
   * @memberOf ZoneService
   */
  constructor(fastify) {
    if (!fastify.ready) throw new Error('Fastify is not initialized');
    else if (!fastify.sequelize) throw new Error('Sequelize is required');

    this.fastify = fastify;
  }

  /**
   * Create new zone
   * @param body - Request body, see zones schema "new"
   * @param userId - User ID
   * @returns {Promise<*>} - Zone
   */
  async create({ body, userId }) {
    const { sequelize, validationError } = this.fastify;

    // Check if domain is in use
    const exists = await sequelize.zones.findOne({
      where: { domain: body.domain },
      attributes: ['id'],
    });
    if (exists) {
      throw validationError({ domain: 'domain already exists' });
    }

    // Create zone in Postgresql
    const zone = await sequelize.zones.create({
      id: crypto.createHash('md5').update(body.domain).digest('hex'),
      ...body,
      user_id: userId,
    });

    // Store configuration in Redis

    return zone;
  }

  /**
   * Get all zones by user
   * @param query
   * @param limit - Limit
   * @param offset - offset
   * @param userId - User ID
   * @returns {Promise<{metadata: {total: *}, zones: *}>} - Zones
   */
  async getAll({ query, limit, offset, userId }) {
    const { sequelize } = this.fastify;

    const zones = await sequelize.zones.findAndCountAll({
      where: { user_id: userId },
    });

    return { metadata: { total: zones.count }, zones: zones.rows };
  }
};
