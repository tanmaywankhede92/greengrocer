const Bill = require('../models/Bill');
const BillItem = require('../models/BillItem');
const BillAdjustment = require('../models/BillAdjustment');
const Customer = require('../models/Customer');

const findBills = async (filters, { page, limit, skip, sort }) => {
  const query = {};

  if (filters.search) {
    const matchingCustomers = await Customer.find({ name: { $regex: filters.search, $options: 'i' }, isDeleted: false }).select('_id').lean();
    const customerIds = matchingCustomers.map((c) => c._id);
    query.$or = [
      { billNumber: { $regex: filters.search, $options: 'i' } },
      ...(customerIds.length > 0 ? [{ customerId: { $in: customerIds } }] : []),
    ];
  }
  if (filters.status && filters.status !== 'all') {
    query.status = filters.status;
  }
  if (filters.from || filters.to) {
    query.billDate = {};
    if (filters.from) query.billDate.$gte = new Date(filters.from);
    if (filters.to) query.billDate.$lte = new Date(filters.to);
  }

  const [bills, total] = await Promise.all([
    Bill.find(query)
      .populate('customerId', 'name mobile')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Bill.countDocuments(query),
  ]);

  const billIds = bills.map((b) => b._id);
  const adjustments = await BillAdjustment.aggregate([
    { $match: { billId: { $in: billIds } } },
    { $group: { _id: '$billId', totalAdjusted: { $sum: '$amount' } } },
  ]);
  const adjustmentMap = Object.fromEntries(adjustments.map((a) => [a._id.toString(), a.totalAdjusted]));

  const mapped = bills.map((b) => {
    const id = b._id.toString();
    const totalAdjusted = adjustmentMap[id] || 0;
    return {
      id: b._id,
      billNumber: b.billNumber,
      customerId: b.customerId?._id,
      customer: b.customerId || null,
      billDate: b.billDate,
      subtotal: b.subtotal,
      deliveryCharge: b.deliveryCharge ?? 0,
      total: b.total,
      totalAdjusted,
      adjustedTotal: b.total - totalAdjusted,
      paidNow: b.paidNow,
      paymentType: b.paymentType,
      notes: b.notes,
      status: b.status,
      createdAt: b.createdAt,
    };
  });

  return { bills: mapped, total };
};

const findById = async (id) => {
  const bill = await Bill.findById(id).populate('customerId').lean();
  if (!bill) return null;

  const [items, adjustments] = await Promise.all([
    BillItem.find({ billId: id }).lean(),
    BillAdjustment.find({ billId: id }).sort({ createdAt: -1 }).lean(),
  ]);

  return {
    bill: {
      ...bill,
      id: bill._id,
      customer: bill.customerId || null,
      deliveryCharge: bill.deliveryCharge ?? 0,
    },
    items: items.map((i) => ({ ...i, id: i._id })),
    adjustments: adjustments.map((a) => ({ ...a, id: a._id })),
  };
};

const createBill = async (data) => {
  return Bill.create(data);
};

const updateStatus = async (id, status) => {
  return Bill.findByIdAndUpdate(id, { status }, { new: true });
};

module.exports = { findBills, findById, createBill, updateStatus };
