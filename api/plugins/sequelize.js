'use strict';

const fp = require('fastify-plugin');
const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const basename = path.basename(__filename);
const models = __dirname + '/../models';

module.exports = fp(
  async (fastify) => {
    const db = {};

    const config = {
      username: process.env.POSTGRES_USERNAME,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DATABASE,
      host: process.env.POSTGRES_HOST,
      port: process.env.POSTGRES_PORT,
      dialect: 'postgres',
      operatorsAliases: 0,
      pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
      define: {
        underscored: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
        deletedAt: 'deleted_at',
      },
      logging: (msg) => fastify.log.debug(msg),
    };

    // Create new instance
    const sequelize = new Sequelize(config);

    // Import models
    fs.readdirSync(models)
      .filter(
        (file) =>
          file.indexOf('.') !== 0 &&
          file !== basename &&
          file.slice(-3) === '.js'
      )
      .forEach((file) => {
        const model = require(path.join(models, file))(
          sequelize,
          Sequelize.DataTypes
        );
        db[model.name] = model;
      });

    // Create database relationships
    Object.keys(db).forEach((modelName) => {
      if (db[modelName].associate) db[modelName].associate(db);
    });

    db.sequelize = sequelize;
    db.Sequelize = Sequelize;

    // Sync models in development
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: true });
    }

    // Make sequelize available to entire application
    fastify.decorate('sequelize', db);

    // Close connection
    fastify.addHook('onClose', async () => await sequelize.close());
  },
  { fastify: '3.x', name: 'plugin-sequelize' }
);
