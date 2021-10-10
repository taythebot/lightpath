'use strict';

const { hash, argon2id } = require('argon2');

module.exports = {
  up: async (queryInterface, _) => {
    const timestamp = new Date();

    await queryInterface.bulkInsert('users', [
      {
        id: 1,
        username: 'admin',
        hash: await hash('password', { type: argon2id }),
        role: 'administrator',
        created_at: timestamp,
        updated_at: timestamp,
      },
    ]);
  },
  down: (queryInterface, Sequelize) => {},
};
