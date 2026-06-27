const mongoose = require('mongoose');
const Customer = require('../models/Customer');
const LedgerEntry = require('../models/LedgerEntry');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');

const findCustomers = async ({ search, page, limit, skip, sort }) => {
  const filter = { isDeleted: false };
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { mobile: { $regex: search, $options: 'i' } },
    ];
  }

  const [customers, total] = await Promise.all([
    Customer.find(filter).sort(sort).skip(skip).limit(limit).lean(),
    Customer.countDocuments(filter),
  ]);

  const customerIds = customers.map((c) => c._id);

  const [ledgerSummaries, billSummaries, paymentSummaries] = await Promise.all([
    LedgerEntry.aggregate([
      { $match: { customerId: { $in: customerIds } } },
      { $group: { _id: '$customerId', balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
    ]),
    Bill.aggregate([
      { $match: { customerId: { $in: customerIds }, status: 'active' } },
      {
        $group: {
          _id: '$customerId',
          billCount: { $sum: 1 },
          lastBillDate: { $max: '$billDate' },
        },
      },
    ]),
    Payment.aggregate([
      { $match: { customerId: { $in: customerIds }, isCancelled: false } },
      { $group: { _id: '$customerId', lastPaymentDate: { $max: '$paymentDate' } } },
    ]),
  ]);

  const ledgerMap = Object.fromEntries(ledgerSummaries.map((l) => [l._id.toString(), l.balance]));
  const billMap = Object.fromEntries(billSummaries.map((b) => [b._id.toString(), b]));
  const paymentMap = Object.fromEntries(paymentSummaries.map((p) => [p._id.toString(), p]));

  const enriched = customers.map((c) => {
    const id = c._id.toString();
    const ledgerBal = ledgerMap[id] || 0;
    const billInfo = billMap[id];
    const payInfo = paymentMap[id];
    return {
      ...c,
      currentDue: (c.openingBalance || 0) + ledgerBal,
      billCount: billInfo?.billCount || 0,
      lastBillDate: billInfo?.lastBillDate || null,
      lastPaymentDate: payInfo?.lastPaymentDate || null,
    };
  });

  return { customers: enriched, total };
};

const findById = async (id) => {
  return Customer.findOne({ _id: id, isDeleted: false });
};

const findByMobile = async (mobile, excludeId = null) => {
  const filter = { mobile, isDeleted: false };
  if (excludeId) filter._id = { $ne: excludeId };
  return Customer.findOne(filter);
};

const createCustomer = async (data) => {
  return Customer.create(data);
};

const updateCustomer = async (id, data) => {
  return Customer.findByIdAndUpdate(id, data, { new: true, runValidators: true });
};

const softDelete = async (id) => {
  return Customer.findByIdAndUpdate(id, { isDeleted: true }, { new: true });
};

module.exports = {
  findCustomers,
  findById,
  findByMobile,
  createCustomer,
  updateCustomer,
  softDelete,
};
