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
   * Zone middleware
   * @param id - Zone ID
   * @param userId - User ID
   * @returns {Promise<*>} - Zone
   */
  async middleware({ id, userId }) {
    const { error, sequelize } = this.fastify;

    const zone = await sequelize.zones.findOne({
      where: { id, user_id: userId },
    });
    if (!zone) {
      throw error({ status: 404, message: 'zone not found' });
    }

    return zone;
  }

  /**
   * Create new zone
   * @param body - Request body, see zones schema "new"
   * @param userId - User ID
   * @returns {Promise<*>} - Zone
   */
  async create({ body, userId }) {
    const { sequelize } = this.fastify;

    // Check if domain is in use
    await this.validateDomain({ domain: body.domain });

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
   * Check if domain is in use
   * @param domain - Domain
   * @returns {Promise<void>}
   */
  async validateDomain({ domain }) {
    const { sequelize, validationError } = this.fastify;

    // Check if domain is in use
    const exists = await sequelize.zones.findOne({
      where: { domain },
      attributes: ['id'],
    });
    if (exists) {
      throw validationError({ domain: 'domain is already in use' });
    }
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

  /**
   * Get zone by id
   * @param id - ID
   * @param userId - User ID
   * @returns {Promise<*>} - Zone
   */
  async get({ id, userId }) {
    const { error, sequelize } = this.fastify;

    const zone = await sequelize.zones.findOne({
      where: { id, user_id: userId },
    });
    if (!zone) throw error({ status: 404, message: 'zone not found' });

    return zone;
  }
};
