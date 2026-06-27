const ApiResponse = require('../helpers/apiResponse');
const messages = require('../constants/messages');

const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return ApiResponse.unauthorized(res, messages.AUTH.UNAUTHORIZED);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return ApiResponse.forbidden(res, messages.AUTH.FORBIDDEN);
    }

    next();
  };
};

module.exports = authorize;
