const User = require('../models/User');

const findByEmail = async (email) => {
  return User.findOne({ email: email.toLowerCase() }).select('+password');
};

const findById = async (id) => {
  return User.findById(id);
};

const createUser = async (userData) => {
  const user = await User.create(userData);
  return User.findById(user.id);
};

const updateRefreshToken = async (userId, refreshToken) => {
  return User.findByIdAndUpdate(userId, { refreshToken }, { new: true });
};

const clearRefreshToken = async (userId) => {
  return User.findByIdAndUpdate(userId, { refreshToken: null }, { new: true });
};

const countUsers = async () => {
  return User.countDocuments();
};

module.exports = {
  findByEmail,
  findById,
  createUser,
  updateRefreshToken,
  clearRefreshToken,
  countUsers,
};
