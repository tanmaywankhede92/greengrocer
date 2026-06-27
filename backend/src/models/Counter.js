const mongoose = require('mongoose');

const counterSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  seq: { type: Number, default: 1 },
  yearMonth: { type: String, required: true },
});

counterSchema.index({ _id: 1, yearMonth: 1 }, { unique: true });

module.exports = mongoose.model('Counter', counterSchema);
