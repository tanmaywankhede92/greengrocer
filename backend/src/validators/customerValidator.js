const Joi = require('joi');

const createCustomerSchema = Joi.object({
  name: Joi.string().trim().min(1).max(120).required()
    .messages({ 'string.empty': 'Customer name is required' }),
  mobile: Joi.string().trim().pattern(/^\d{10}$/).required()
    .messages({ 'string.pattern.base': 'Mobile number must be exactly 10 digits' }),
  address: Joi.string().trim().max(300).allow('').optional(),
  gstNumber: Joi.string().trim().max(20).allow('').optional(),
  openingBalance: Joi.number().default(0),
  notes: Joi.string().trim().max(500).allow('').optional(),
});

const updateCustomerSchema = Joi.object({
  name: Joi.string().trim().min(1).max(120).optional(),
  mobile: Joi.string().trim().pattern(/^\d{10}$/).optional()
    .messages({ 'string.pattern.base': 'Mobile number must be exactly 10 digits' }),
  address: Joi.string().trim().max(300).allow('').optional(),
  gstNumber: Joi.string().trim().max(20).allow('').optional(),
  notes: Joi.string().trim().max(500).allow('').optional(),
}).min(1).messages({ 'object.min': 'At least one field must be provided' });

module.exports = { createCustomerSchema, updateCustomerSchema };
