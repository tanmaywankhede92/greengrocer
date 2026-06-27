const logger = require('../helpers/logger');
const ApiResponse = require('../helpers/apiResponse');
const httpStatus = require('../constants/httpStatus');
const messages = require('../constants/messages');

const errorHandler = (err, req, res, _next) => {
  logger.error(`${err.name}: ${err.message}`, {
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    return ApiResponse.badRequest(res, messages.VALIDATION.ERROR, errors);
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern)[0];
    return ApiResponse.conflict(res, `${field} already exists`);
  }

  if (err.name === 'CastError') {
    return ApiResponse.badRequest(res, `Invalid ${err.path}: ${err.value}`);
  }

  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return ApiResponse.unauthorized(res, messages.AUTH.INVALID_TOKEN);
  }

  const statusCode = err.statusCode || httpStatus.INTERNAL;
  const message = err.statusCode ? err.message : messages.SERVER.ERROR;
  return ApiResponse.error(res, message, statusCode);
};

module.exports = errorHandler;
