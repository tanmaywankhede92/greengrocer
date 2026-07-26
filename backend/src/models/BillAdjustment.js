const mongoose = require('mongoose');

const billAdjustmentSchema = new mongoose.Schema({
  billId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bill',
    required: true,
    index: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: true,
  },
  billItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'BillItem',
    default: null,
    index: true,
  },
  originalQuantity: {
    type: Number,
    default: null,
  },
  adjustedQuantity: {
    type: Number,
    default: null,
  },
  amount: {
    type: Number,
    required: true,
    min: 0.01,
  },
  reason: {
    type: String,
    required: true,
    enum: ['damaged', 'missing', 'short_supply', 'rate_diff', 'other'],
  },
  note: {
    type: String,
    default: '',
    maxlength: 300,
  },
  adjustmentDate: {
    type: Date,
    default: Date.now,
    required: true,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });

billAdjustmentSchema.index({ billId: 1, createdAt: -1 });
billAdjustmentSchema.index({ customerId: 1 });

module.exports = mongoose.model('BillAdjustment', billAdjustmentSchema);
