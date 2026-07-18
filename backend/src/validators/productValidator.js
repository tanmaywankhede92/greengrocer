const Joi = require('joi');

const createProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(80).required()
    .messages({ 'string.empty': 'Product name is required' }),
  nameHindi: Joi.string().trim().max(80).allow('').default(''),
  unit: Joi.string().trim().max(30).default('kg'),
});

const updateProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(80).optional(),
  nameHindi: Joi.string().trim().max(80).allow('').optional(),
  unit: Joi.string().trim().max(30).optional(),
}).min(1);

const toggleProductSchema = Joi.object({
  isActive: Joi.boolean().required(),
});

module.exports = { createProductSchema, updateProductSchema, toggleProductSchema };
