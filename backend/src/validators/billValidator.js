const Joi = require('joi');
const { PRODUCT_UNITS, PAYMENT_MODES } = require('../constants/enums');

const itemSchema = Joi.object({
  productId: Joi.string().allow(null, '').optional(),
  productName: Joi.string().trim().min(1).max(80).required(),
  unit: Joi.string().valid(...PRODUCT_UNITS).required(),
  quantity: Joi.number().positive().required()
    .messages({ 'number.positive': 'Quantity must be greater than 0' }),
  defaultRate: Joi.number().min(0).default(0),
  appliedRate: Joi.number().positive().required()
    .messages({ 'number.positive': 'Rate must be greater than 0' }),
});

const createBillSchema = Joi.object({
  customerId: Joi.string().required()
    .messages({ 'string.empty': 'Customer is required' }),
  billDate: Joi.date().required(),
  items: Joi.array().items(itemSchema).min(1).required()
    .messages({ 'array.min': 'At least one item is required' }),
  discount: Joi.number().min(0).default(0),
  notes: Joi.string().trim().max(500).allow('').default(''),
  paymentAmount: Joi.number().min(0).default(0),
  paymentMode: Joi.string().valid(...PAYMENT_MODES).default('cash'),
});

module.exports = { createBillSchema };
