const Payment = require('../models/Payment');

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
      .populate('customerId', 'name mobile')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Payment.countDocuments(query),
  ]);

  const mapped = payments.map((p) => ({
    ...p,
    id: p._id,
    customer: p.customerId || null,
  }));

  return { payments: mapped, total };
};

const findById = async (id) => {
  return Payment.findById(id).populate('customerId', 'name mobile').lean();
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
