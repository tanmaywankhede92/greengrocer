const mongoose = require('mongoose');
const LedgerEntry = require('../models/LedgerEntry');

const toEndOfDay = (dateStr) => {
  const d = new Date(dateStr);
  d.setUTCHours(23, 59, 59, 999);
  return d;
};

const findByCustomer = async (customerId, range = {}) => {
  const match = { customerId: new mongoose.Types.ObjectId(customerId) };
  if (range.from || range.to) {
    match.entryDate = {};
    if (range.from) match.entryDate.$gte = new Date(range.from);
    if (range.to) match.entryDate.$lte = toEndOfDay(range.to);
  }
  return LedgerEntry.find(match).sort({ entryDate: 1, createdAt: 1 }).lean();
};

const getOpeningBalance = async (customerId, beforeDate) => {
  const result = await LedgerEntry.aggregate([
    {
      $match: {
        customerId: new mongoose.Types.ObjectId(customerId),
        entryDate: { $lt: new Date(beforeDate) },
      },
    },
    { $group: { _id: null, balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
  ]);
  return result.length > 0 ? result[0].balance : 0;
};

const createEntry = async (data) => {
  return LedgerEntry.create(data);
};

const getCustomerBalance = async (customerId) => {
  const result = await LedgerEntry.aggregate([
    { $match: { customerId: new mongoose.Types.ObjectId(customerId) } },
    { $group: { _id: null, balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
  ]);
  return result.length > 0 ? result[0].balance : 0;
};

const getCustomerBalances = async (customerIds) => {
  return LedgerEntry.aggregate([
    { $match: { customerId: { $in: customerIds.map((id) => new mongoose.Types.ObjectId(id)) } } },
    { $group: { _id: '$customerId', balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
  ]);
};

module.exports = { findByCustomer, getOpeningBalance, createEntry, getCustomerBalance, getCustomerBalances };
