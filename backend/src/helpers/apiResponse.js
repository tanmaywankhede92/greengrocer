const httpStatus = require('../constants/httpStatus');

class ApiResponse {
  static success(res, data = null, message = 'Success', statusCode = httpStatus.OK, meta = null) {
    const response = { success: true, message, data };
    if (meta) response.meta = meta;
    return res.status(statusCode).json(response);
  }

  static created(res, data = null, message = 'Created') {
    return this.success(res, data, message, httpStatus.CREATED);
  }

  static paginated(res, data, meta) {
    return this.success(res, data, 'Success', httpStatus.OK, meta);
  }

  static error(res, message = 'Error', statusCode = httpStatus.INTERNAL, errors = null) {
    const response = { success: false, message };
    if (errors) response.errors = errors;
    return res.status(statusCode).json(response);
  }

  static badRequest(res, message = 'Bad request', errors = null) {
    return this.error(res, message, httpStatus.BAD_REQUEST, errors);
  }

  static unauthorized(res, message = 'Unauthorized') {
    return this.error(res, message, httpStatus.UNAUTHORIZED);
  }

  static forbidden(res, message = 'Forbidden') {
    return this.error(res, message, httpStatus.FORBIDDEN);
  }

  static notFound(res, message = 'Not found') {
    return this.error(res, message, httpStatus.NOT_FOUND);
  }

  static conflict(res, message = 'Conflict') {
    return this.error(res, message, httpStatus.CONFLICT);
  }
}

module.exports = ApiResponse;
