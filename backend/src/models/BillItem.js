const mongoose = require('mongoose');
const { PRODUCT_UNITS } = require('../constants/enums');

const billItemSchema = new mongoose.Schema({
  billId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bill',
    required: true,
    index: true,
  },
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    default: null,
  },
  productName: {
    type: String,
    required: true,
  },
  unit: {
    type: String,
    enum: PRODUCT_UNITS,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 0,
  },
  defaultRate: {
    type: Number,
    default: 0,
  },
  appliedRate: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
  },
}, { timestamps: { createdAt: true, updatedAt: false } });


billItemSchema.index({ productId: 1 });

module.exports = mongoose.model('BillItem', billItemSchema);
