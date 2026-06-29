const mongoose = require('mongoose');
const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true,
    maxlength: 80,
  },
  unit: {
    type: String,
    default: 'kg',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
}, { timestamps: true });

productSchema.index({ name: 1, isDeleted: 1 }, { unique: true });
productSchema.index({ isActive: 1 });
productSchema.index({ isDeleted: 1 });
productSchema.index({ name: 'text' });

module.exports = mongoose.model('Product', productSchema);
