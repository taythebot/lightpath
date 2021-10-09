'use strict'

const UserService = require('../../services/user')
const schemas = require('./schemas')

module.exports = async (fastify, _) => {
  const userService = new UserService(fastify)

  // Get all users
  fastify.get('/', { schema: schemas.getAll }, async (req, _) => {
    const users = await userService.getAll()
    return { users }
  })

  // Get user
  fastify.get(
    '/:username',
    {
      schema: schemas.getUser,
      config: {
        errors: { params: { status: 404, message: 'user not found' } },
      },
    },
    async (req, _) => {
      const user = await userService.getUser(req.params.username)
      return { user }
    }
  )
}
