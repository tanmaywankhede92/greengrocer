const mongoose = require('mongoose');

const businessSettingSchema = new mongoose.Schema({
  businessName: {
    type: String,
    default: 'Rathod Enterprises',
    trim: true,
    maxlength: 200,
  },
  tagline: {
    type: String,
    default: 'Vegetable & Fruit Wholesale Supplier',
    trim: true,
    maxlength: 200,
  },
  address: {
    type: String,
    default: '',
    trim: true,
    maxlength: 500,
  },
  phone: {
    type: String,
    default: '',
    trim: true,
    maxlength: 20,
  },
  gstNumber: {
    type: String,
    default: '',
    trim: true,
    maxlength: 20,
  },
  billPrefix: {
    type: String,
    default: '',
    trim: true,
    maxlength: 10,
  },
  invoicePrefix: {
    type: String,
    default: 'INV',
    trim: true,
    maxlength: 10,
  },
  footerNote: {
    type: String,
    default: 'Thank you for your business!',
    trim: true,
    maxlength: 300,
  },
}, { timestamps: true });

module.exports = mongoose.model('BusinessSetting', businessSettingSchema);
