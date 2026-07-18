const mongoose = require('mongoose');

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
  productNameHindi: {
    type: String,
    default: '',
  },
  unit: {
    type: String,
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
