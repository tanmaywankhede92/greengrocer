const Joi = require('joi');
const { PRODUCT_UNITS } = require('../constants/enums');

const createProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(80).required()
    .messages({ 'string.empty': 'Product name is required' }),
  unit: Joi.string().valid(...PRODUCT_UNITS).default('kg'),
});

const updateProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(80).optional(),
  unit: Joi.string().valid(...PRODUCT_UNITS).optional(),
}).min(1);

const toggleProductSchema = Joi.object({
  isActive: Joi.boolean().required(),
});

module.exports = { createProductSchema, updateProductSchema, toggleProductSchema };
