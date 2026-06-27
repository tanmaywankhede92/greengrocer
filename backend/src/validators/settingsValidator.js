const Joi = require('joi');

const updateSettingsSchema = Joi.object({
  businessName: Joi.string().trim().max(200).optional(),
  tagline: Joi.string().trim().max(200).allow('').optional(),
  address: Joi.string().trim().max(500).allow('').optional(),
  phone: Joi.string().trim().max(20).allow('').optional(),
  gstNumber: Joi.string().trim().max(20).allow('').optional(),
  invoicePrefix: Joi.string().trim().max(10).optional(),
  footerNote: Joi.string().trim().max(300).allow('').optional(),
}).min(1);

module.exports = { updateSettingsSchema };
