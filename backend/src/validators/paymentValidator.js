const Joi = require('joi');
const { PAYMENT_MODES } = require('../constants/enums');

const createPaymentSchema = Joi.object({
  customerId: Joi.string().required()
    .messages({ 'string.empty': 'Customer is required' }),
  amount: Joi.number().positive().required()
    .messages({
      'number.positive': 'Amount must be greater than 0',
      'number.base': 'Amount must be a number',
    }),
  mode: Joi.string().valid(...PAYMENT_MODES).default('cash'),
  reference: Joi.string().trim().max(100).allow('').default(''),
  notes: Joi.string().trim().max(300).allow('').default(''),
  paymentDate: Joi.date().required(),
});

module.exports = { createPaymentSchema };
