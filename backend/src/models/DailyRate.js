const mongoose = require('mongoose');

const dailyRateSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: [true, 'Product is required'],
  },
  rate: {
    type: Number,
    required: [true, 'Rate is required'],
    min: 0,
  },
  rateDate: {
    type: Date,
    required: [true, 'Rate date is required'],
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });

dailyRateSchema.index({ productId: 1, rateDate: 1 }, { unique: true });
dailyRateSchema.index({ rateDate: 1 });
dailyRateSchema.index({ productId: 1 });

module.exports = mongoose.model('DailyRate', dailyRateSchema);
