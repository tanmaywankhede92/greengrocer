const jwt = require('jsonwebtoken');
const config = require('../config');
const userRepository = require('../repositories/userRepository');

const generateTokens = (userId, role) => {
  const accessToken = jwt.sign(
    { sub: userId, role },
    config.jwt.accessSecret,
    { expiresIn: config.jwt.accessExpiry },
  );

  const refreshToken = jwt.sign(
    { sub: userId, role, type: 'refresh' },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiry },
  );

  return { accessToken, refreshToken };
};

const verifyRefreshToken = (token) => {
  return jwt.verify(token, config.jwt.refreshSecret);
};

const register = async ({ email, password, fullName }) => {
  const existing = await userRepository.findByEmail(email);
  if (existing) {
    const error = new Error('An account with this email already exists');
    error.statusCode = 409;
    throw error;
  }

  const userCount = await userRepository.countUsers();
  const role = userCount === 0 ? 'admin' : 'staff';

  const user = await userRepository.createUser({ email, password, fullName, role });
  const tokens = generateTokens(user.id, user.role);

  await userRepository.updateRefreshToken(user.id, tokens.refreshToken);

  return {
    user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role },
    ...tokens,
  };
};

const login = async ({ email, password }) => {
  const user = await userRepository.findByEmail(email);
  if (!user) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  if (!user.isActive) {
    const error = new Error('Account is deactivated');
    error.statusCode = 403;
    throw error;
  }

  const tokens = generateTokens(user.id, user.role);
  await userRepository.updateRefreshToken(user.id, tokens.refreshToken);

  return {
    user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role },
    ...tokens,
  };
};

const refresh = async (refreshToken) => {
  try {
    const decoded = verifyRefreshToken(refreshToken);
    const user = await userRepository.findById(decoded.sub);

    if (!user || !user.isActive) {
      const error = new Error('Invalid token');
      error.statusCode = 401;
      throw error;
    }

    const tokens = generateTokens(user.id, user.role);
    await userRepository.updateRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  } catch (err) {
    if (err.statusCode) throw err;
    const error = new Error('Invalid or expired refresh token');
    error.statusCode = 401;
    throw error;
  }
};

const logout = async (userId) => {
  await userRepository.clearRefreshToken(userId);
};

const getProfile = async (userId) => {
  const user = await userRepository.findById(userId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }
  return { id: user.id, email: user.email, fullName: user.fullName, role: user.role, createdAt: user.createdAt };
};

module.exports = { register, login, refresh, logout, getProfile };
