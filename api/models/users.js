'use strict';

module.exports = (sequelize, DataTypes) => {
  const Users = sequelize.define('users', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    username: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true,
    },
    hash: {
      type: DataTypes.STRING(96),
      allowNull: false,
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
    },
  });

  Users.associate = (sequelize) => {
    Users.hasMany(sequelize.zones, {
      foreignKey: 'user_id',
      sourceKey: 'id',
    });
  };

  return Users;
};
