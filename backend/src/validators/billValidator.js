const Joi = require('joi');
const { PAYMENT_MODES } = require('../constants/enums');

const itemSchema = Joi.object({
  productId: Joi.string().allow(null, '').optional(),
  productName: Joi.string().trim().min(1).max(80).required(),
  productNameHindi: Joi.string().trim().max(80).allow('').default(''),
  unit: Joi.string().trim().max(30).required(),
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
  deliveryCharge: Joi.number().min(0).default(0),
  notes: Joi.string().trim().max(500).allow('').default(''),
  paymentAmount: Joi.number().min(0).default(0),
  paymentMode: Joi.string().valid(...PAYMENT_MODES).default('cash'),
});

const adjustBillSchema = Joi.object({
  amount: Joi.number().positive().required()
    .messages({ 'number.positive': 'Adjustment amount must be greater than 0' }),
  reason: Joi.string().valid('damaged', 'missing', 'short_supply', 'rate_diff', 'other').required(),
  note: Joi.string().trim().max(300).allow('').default(''),
});

module.exports = { createBillSchema, adjustBillSchema };
