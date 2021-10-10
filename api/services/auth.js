'use strict';

const { verify, argon2id } = require('argon2');

module.exports = class AuthService {
  /**
   * Creates new instance of AuthService
   * @param fastify
   * @memberOf AuthService
   */
  constructor(fastify) {
    if (!fastify.ready) throw new Error('Fastify is not initialized');
    else if (!fastify.sequelize) throw new Error('Sequelize is required');

    this.fastify = fastify;
  }

  /**
   * Login user
   * @param username - Username
   * @param password - Password
   * @returns {Promise<*>} - User ID
   */
  async login({ username, password }) {
    const { error, sequelize } = this.fastify;

    const user = await sequelize.users.findOne({
      where: { username },
      attributes: ['id', 'username', 'hash', 'role'],
    });
    if (!user) {
      throw error({ status: 400, message: 'invalid username or password' });
    }

    const valid = await verify(user.hash, password, { type: argon2id });
    if (!valid) {
      throw error({ status: 400, message: 'invalid username or password' });
    }

    return user;
  }
};
