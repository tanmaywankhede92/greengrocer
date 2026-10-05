const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const LedgerEntry = require('../models/LedgerEntry');

const DAY_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

const startOfDay = (value) => {
  const match = DAY_ONLY.exec(String(value || '').trim());
  if (match) {
    return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), 0, 0, 0, 0);
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return new Date(parsed.getFullYear(), parsed.getMonth(), parsed.getDate(), 0, 0, 0, 0);
};

const endOfDay = (value) => {
  const start = startOfDay(value);
  if (!start) return null;
  return new Date(start.getFullYear(), start.getMonth(), start.getDate(), 23, 59, 59, 999);
};

const findPayments = async (customerId = null, filters = {}) => {
  const { page = 1, limit = 20, skip = 0, sort = { createdAt: -1 } } = filters;

  const query = {};
  if (customerId) query.customerId = customerId;

  if (filters.from || filters.to) {
    query.paymentDate = {};
    const from = startOfDay(filters.from);
    const to = endOfDay(filters.to);
    if (from) query.paymentDate.$gte = from;
    if (to) query.paymentDate.$lte = to;
  }

  if (filters.mode) query.mode = filters.mode;

  if (filters.isCancelled !== undefined && filters.isCancelled !== '') {
    query.isCancelled = filters.isCancelled === true || filters.isCancelled === 'true';
  }

  const [payments, total] = await Promise.all([
    Payment.find(query)
      .populate('customerId', 'name mobile address openingBalance')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Payment.countDocuments(query),
  ]);

  const customerIds = [...new Set(payments.map((p) => p.customerId?._id?.toString()).filter(Boolean))];
  const balances = await LedgerEntry.aggregate([
    { $match: { customerId: { $in: customerIds.map((id) => new mongoose.Types.ObjectId(id)) } } },
    { $group: { _id: '$customerId', balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
  ]);
  const balanceMap = Object.fromEntries(balances.map((b) => [b._id.toString(), b.balance]));

  const mapped = payments.map((p) => {
    let customer = null;
    if (p.customerId && typeof p.customerId === 'object') {
      const cId = p.customerId._id.toString();
      const currentDue = (p.customerId.openingBalance || 0) + (balanceMap[cId] || 0);
      customer = {
        ...p.customerId,
        id: p.customerId._id,
        currentDue,
      };
    }
    return {
      ...p,
      id: p._id,
      customer,
    };
  });

  return { payments: mapped, total };
};

const findById = async (id) => {
  const payment = await Payment.findById(id).populate('customerId', 'name mobile address openingBalance').lean();
  if (!payment) return null;
  let customer = null;
  if (payment.customerId && typeof payment.customerId === 'object') {
    const cId = payment.customerId._id;
    const balance = await LedgerEntry.aggregate([
      { $match: { customerId: new mongoose.Types.ObjectId(cId) } },
      { $group: { _id: '$customerId', balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
    ]);
    const ledgerBal = balance.length > 0 ? balance[0].balance : 0;
    customer = {
      ...payment.customerId,
      id: payment.customerId._id,
      currentDue: (payment.customerId.openingBalance || 0) + ledgerBal,
    };
  }
  return {
    ...payment,
    id: payment._id,
    customer,
  };
};

const createPayment = async (data) => {
  return Payment.create(data);
};

const cancelPayment = async (id) => {
  return Payment.findByIdAndUpdate(id, { isCancelled: true }, { new: true });
};

const findByBillId = async (billId) => {
  return Payment.findOne({ billId, isCancelled: false });
};

module.exports = { findPayments, findById, createPayment, cancelPayment, findByBillId, startOfDay, endOfDay };
