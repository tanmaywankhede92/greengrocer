const Joi = require('joi');

const upsertRateSchema = Joi.object({
  productId: Joi.string().required()
    .messages({ 'string.empty': 'Product is required' }),
  rate: Joi.number().positive().required()
    .messages({
      'number.positive': 'Rate must be greater than 0',
      'number.base': 'Rate must be a number',
    }),
  rateDate: Joi.date().required()
    .messages({ 'date.base': 'Valid date is required' }),
});

module.exports = { upsertRateSchema };
