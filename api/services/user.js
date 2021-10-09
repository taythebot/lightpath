'use strict'

module.exports = class UserService {
  /**
   * Creates new instance of UserService
   * @param fastify
   * @memberOf UserService
   */
  constructor(fastify) {
    if (!fastify.ready) throw new Error('Fastify is not initialized')
    else if (!fastify.sequelize) throw new Error('Sequelize is required')

    this.fastify = fastify
  }

  /**
   * Get all users
   * @returns {Promise<*>} - Users
   */
  async getAll() {
    const { sequelize } = this.fastify

    return await sequelize.users.findAll()
  }

  /**
   * Get user by username
   * @param username - Username
   * @returns {Promise<*>} - User
   */
  async getUser(username) {
    const { sequelize, error } = this.fastify

    const user = await sequelize.users.findOne({ where: { username } })
    if (!user) {
      throw error({ code: 'UserNotFound' })

      // Override the default status code and message for error
      // throw error({
      //   code: 'UserNotFound',
      //   status: 500,
      //   message: 'custom message',
      // })
    }

    return user
  }
}
