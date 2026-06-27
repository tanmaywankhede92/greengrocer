const mongoose = require('mongoose');
const { PAYMENT_MODES } = require('../constants/enums');

const paymentSchema = new mongoose.Schema({
  receiptNumber: {
    type: String,
    required: true,
    unique: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer is required'],
  },
  amount: {
    type: Number,
    required: [true, 'Amount is required'],
    min: 0.01,
  },
  mode: {
    type: String,
    enum: PAYMENT_MODES,
    default: 'cash',
  },
  reference: {
    type: String,
    default: '',
    maxlength: 100,
  },
  notes: {
    type: String,
    default: '',
    maxlength: 300,
  },
  paymentDate: {
    type: Date,
    required: true,
  },
  billId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bill',
    default: null,
  },
  isCancelled: {
    type: Boolean,
    default: false,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });


paymentSchema.index({ customerId: 1, createdAt: -1 });
paymentSchema.index({ paymentDate: 1 });
paymentSchema.index({ billId: 1 });
paymentSchema.index({ isCancelled: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
