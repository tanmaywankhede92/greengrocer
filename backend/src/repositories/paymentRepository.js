const Payment = require('../models/Payment');

const findPayments = async (customerId = null, page, limit, skip, sort) => {
  const query = {};
  if (customerId) query.customerId = customerId;

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

module.exports = { findPayments, findById, createPayment, cancelPayment, findByBillId };
