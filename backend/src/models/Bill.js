const mongoose = require('mongoose');
const { BILL_STATUSES } = require('../constants/enums');

const billSchema = new mongoose.Schema({
  billNumber: {
    type: String,
    required: true,
    unique: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer is required'],
  },
  billDate: {
    type: Date,
    required: true,
  },
  subtotal: {
    type: Number,
    default: 0,
  },
  discount: {
    type: Number,
    default: 0,
  },
  total: {
    type: Number,
    default: 0,
  },
  previousDue: {
    type: Number,
    default: 0,
  },
  paidNow: {
    type: Number,
    default: 0,
  },
  newDue: {
    type: Number,
    default: 0,
  },
  paymentType: {
    type: String,
    enum: ['cash', 'partial', 'credit'],
    default: 'credit',
  },
  notes: {
    type: String,
    default: '',
    maxlength: 500,
  },
  status: {
    type: String,
    enum: BILL_STATUSES,
    default: 'active',
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });

billSchema.index({ billNumber: 1 }, { unique: true });
billSchema.index({ customerId: 1, createdAt: -1 });
billSchema.index({ billDate: 1 });
billSchema.index({ status: 1 });
billSchema.index({ customerId: 1, status: 1 });
billSchema.index({ billNumber: 'text' });

module.exports = mongoose.model('Bill', billSchema);
