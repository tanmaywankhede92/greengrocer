const jwt = require('jsonwebtoken');
const config = require('../config');
const ApiResponse = require('../helpers/apiResponse');
const messages = require('../constants/messages');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return ApiResponse.unauthorized(res, messages.AUTH.UNAUTHORIZED);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.accessSecret);
    req.user = {
      id: decoded.sub,
      role: decoded.role,
    };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return ApiResponse.unauthorized(res, messages.AUTH.TOKEN_EXPIRED);
    }
    return ApiResponse.unauthorized(res, messages.AUTH.INVALID_TOKEN);
  }
};

module.exports = authenticate;
