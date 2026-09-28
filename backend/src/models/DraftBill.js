const mongoose = require('mongoose');

const draftItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    default: null,
  },
  productName: {
    type: String,
    required: true,
    trim: true,
  },
  productNameHindi: {
    type: String,
    default: '',
    trim: true,
  },
  unit: {
    type: String,
    default: 'kg',
    trim: true,
  },
  quantity: {
    type: Number,
    default: 1,
    min: 0,
  },
  defaultRate: {
    type: Number,
    default: 0,
    min: 0,
  },
  appliedRate: {
    type: Number,
    default: 0,
    min: 0,
  },
  amount: {
    type: Number,
    default: 0,
    min: 0,
  },
}, { _id: false });

const draftBillSchema = new mongoose.Schema({
  draftId: {
    type: String,
    required: true,
    unique: true,
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    default: null,
  },
  customerName: {
    type: String,
    default: '',
    trim: true,
  },
  customerMobile: {
    type: String,
    default: '',
    trim: true,
  },
  customerAddress: {
    type: String,
    default: '',
    trim: true,
  },
  billDate: {
    type: Date,
    default: Date.now,
  },
  items: [draftItemSchema],
  subtotal: {
    type: Number,
    default: 0,
  },
  deliveryCharge: {
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
  notes: {
    type: String,
    default: '',
    maxlength: 500,
  },
  paymentAmount: {
    type: Number,
    default: 0,
  },
  paymentMode: {
    type: String,
    default: 'cash',
  },
  status: {
    type: String,
    enum: ['draft', 'converted', 'discarded'],
    default: 'draft',
  },
  convertedBillId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bill',
    default: null,
  },
  convertedBillNumber: {
    type: String,
    default: null,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
}, { timestamps: true });

draftBillSchema.index({ status: 1, updatedAt: -1 });
draftBillSchema.index({ customerId: 1 });

module.exports = mongoose.model('DraftBill', draftBillSchema);
