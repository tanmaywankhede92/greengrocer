const Joi = require('joi');

const registerSchema = Joi.object({
  email: Joi.string().email().max(255).required()
    .messages({
      'string.email': 'Enter a valid email',
      'string.empty': 'Email is required',
    }),
  password: Joi.string().min(6).max(72).required()
    .messages({
      'string.min': 'Password must be at least 6 characters',
      'string.empty': 'Password is required',
    }),
  fullName: Joi.string().trim().max(100).required()
    .messages({
      'string.empty': 'Full name is required',
    }),
});

const loginSchema = Joi.object({
  email: Joi.string().email().max(255).required()
    .messages({
      'string.email': 'Enter a valid email',
      'string.empty': 'Email is required',
    }),
  password: Joi.string().required()
    .messages({
      'string.empty': 'Password is required',
    }),
});

const refreshSchema = Joi.object({
  refreshToken: Joi.string().required()
    .messages({
      'string.empty': 'Refresh token is required',
    }),
});

module.exports = { registerSchema, loginSchema, refreshSchema };
