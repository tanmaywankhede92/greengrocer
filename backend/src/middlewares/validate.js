const ApiResponse = require('../helpers/apiResponse');
const messages = require('../constants/messages');

const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));
      return ApiResponse.badRequest(res, messages.VALIDATION.ERROR, errors);
    }

    req[source] = value;
    next();
  };
};

module.exports = validate;
