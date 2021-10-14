'use strict';

module.exports = (sequelize, DataTypes) => {
  const Zones = sequelize.define('zones', {
    id: {
      type: DataTypes.STRING(32),
      primaryKey: true,
    },
    domain: {
      type: DataTypes.STRING(100),
      allowNull: false,
      unique: true,
    },
    origin: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    enforce_https: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    ssl_auto: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    ssl_certificate: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    ssl_private_key: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    cache_enabled: {
      type: DataTypes.VIRTUAL,
      get() {
        return this.getDataValue('cache_ttl') !== 'Bypass';
      },
    },
    cache_ttl: {
      type: DataTypes.STRING(6),
      allowNull: false,
      defaultValue: '3600',
    },
    cache_query: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    cache_cookie: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    security_cors: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    security_waf: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    security_crawlers: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    status: {
      type: DataTypes.STRING(20),
      allowNUll: false,
      defaultValue: 'active',
    },
  });

  Zones.associate = (sequelize) => {
    Zones.belongsTo(sequelize.users, {
      foreignKey: 'user_id',
      targetKey: 'id',
    });
  };

  return Zones;
};
