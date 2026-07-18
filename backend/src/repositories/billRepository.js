const Bill = require('../models/Bill');
const BillItem = require('../models/BillItem');
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

  const mapped = bills.map((b) => ({
    id: b._id,
    billNumber: b.billNumber,
    customerId: b.customerId?._id,
    customer: b.customerId || null,
    billDate: b.billDate,
    subtotal: b.subtotal,
    deliveryBoyName: b.deliveryBoyName || '',
    deliveryBoyPhone: b.deliveryBoyPhone || '',
    total: b.total,
    paidNow: b.paidNow,
    newDue: b.newDue,
    paymentType: b.paymentType,
    notes: b.notes,
    status: b.status,
    createdAt: b.createdAt,
  }));

  return { bills: mapped, total };
};

const findById = async (id) => {
  const bill = await Bill.findById(id).populate('customerId').lean();
  if (!bill) return null;

  const items = await BillItem.find({ billId: id }).lean();

  return {
    bill: {
      ...bill,
      id: bill._id,
      customer: bill.customerId || null,
      deliveryBoyName: bill.deliveryBoyName || '',
      deliveryBoyPhone: bill.deliveryBoyPhone || '',
    },
    items: items.map((i) => ({ ...i, id: i._id })),
  };
};

const createBill = async (data) => {
  return Bill.create(data);
};

const updateStatus = async (id, status) => {
  return Bill.findByIdAndUpdate(id, { status }, { new: true });
};

module.exports = { findBills, findById, createBill, updateStatus };
