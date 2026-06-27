const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true,
    maxlength: 120,
  },
  mobile: {
    type: String,
    required: [true, 'Mobile number is required'],
    trim: true,
  },
  address: {
    type: String,
    trim: true,
    default: '',
    maxlength: 300,
  },
  gstNumber: {
    type: String,
    trim: true,
    default: '',
    maxlength: 20,
  },
  openingBalance: {
    type: Number,
    default: 0,
  },
  notes: {
    type: String,
    trim: true,
    default: '',
    maxlength: 500,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });

customerSchema.index({ mobile: 1, isDeleted: 1 });
customerSchema.index({ name: 1 });
customerSchema.index({ isDeleted: 1 });
customerSchema.index({ name: 'text', mobile: 'text' });

module.exports = mongoose.model('Customer', customerSchema);
