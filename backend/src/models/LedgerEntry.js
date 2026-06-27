const mongoose = require('mongoose');
const { LEDGER_ENTRY_TYPES } = require('../constants/enums');

const ledgerEntrySchema = new mongoose.Schema({
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer is required'],
  },
  entryType: {
    type: String,
    enum: LEDGER_ENTRY_TYPES,
    required: [true, 'Entry type is required'],
  },
  entryDate: {
    type: Date,
    required: true,
  },
  description: {
    type: String,
    default: '',
    maxlength: 200,
  },
  debit: {
    type: Number,
    default: 0,
  },
  credit: {
    type: Number,
    default: 0,
  },
  referenceId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: { createdAt: true, updatedAt: false } });

ledgerEntrySchema.index({ customerId: 1, entryDate: 1, createdAt: 1 });
ledgerEntrySchema.index({ customerId: 1, entryDate: -1 });
ledgerEntrySchema.index({ entryType: 1 });
ledgerEntrySchema.index({ referenceId: 1 });

module.exports = mongoose.model('LedgerEntry', ledgerEntrySchema);
