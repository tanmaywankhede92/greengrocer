const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');
const Customer = require('../models/Customer');
const LedgerEntry = require('../models/LedgerEntry');

const getDashboard = async () => {
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(todayStart.getTime() + 86400000);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
  const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

  const [
    todayBills,
    monthPayments,
    customerList,
    recentBillsData,
    recentPaymentsData,
    monthlySalesData,
    allLedgerBalances,
  ] = await Promise.all([
    Bill.find({ billDate: { $gte: todayStart, $lt: todayEnd }, status: 'active' }).lean(),
    Payment.find({ paymentDate: { $gte: monthStart, $lte: monthEnd }, isCancelled: false }).lean(),
    Customer.find({ isDeleted: false }).lean(),
    Bill.find()
      .populate('customerId', 'name mobile')
      .sort({ createdAt: -1 })
      .limit(6)
      .lean(),
    Payment.find({ isCancelled: false })
      .populate('customerId', 'name mobile')
      .sort({ createdAt: -1 })
      .limit(6)
      .lean(),
    Bill.find({ status: 'active', billDate: { $gte: sixMonthsAgo } })
      .select('billDate total')
      .lean(),
    LedgerEntry.aggregate([
      { $group: { _id: '$customerId', balance: { $sum: { $subtract: ['$debit', '$credit'] } } } },
    ]),
  ]);

  const todayRevenue = todayBills.reduce((s, b) => s + b.total, 0);
  const todayOrders = todayBills.length;
  const monthlyCollection = monthPayments.reduce((s, p) => s + p.amount, 0);

  const ledgerMap = {};
  allLedgerBalances.forEach((l) => {
    ledgerMap[l._id.toString()] = l.balance;
  });

  const customersWithDue = customerList.map((c) => {
    const id = c._id.toString();
    const ledgerBal = ledgerMap[id] || 0;
    const currentDue = (c.openingBalance || 0) + ledgerBal;
    return { id: c._id, name: c.name, mobile: c.mobile, currentDue };
  });

  const outstanding = customersWithDue.reduce((s, c) => s + Math.max(c.currentDue, 0), 0);
  const totalCustomers = customersWithDue.length;
  const pendingCustomers = customersWithDue.filter((c) => c.currentDue > 0).length;

  const topCustomers = [...customersWithDue]
    .filter((c) => c.currentDue > 0)
    .sort((a, b) => b.currentDue - a.currentDue)
    .slice(0, 5);

  const byMonth = {};
  monthlySalesData.forEach((b) => {
    const d = new Date(b.billDate);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    byMonth[key] = (byMonth[key] || 0) + b.total;
  });

  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const salesSeries = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    salesSeries.push({ month: monthNames[d.getMonth()], sales: byMonth[key] || 0 });
  }

  const recentBills = recentBillsData.map((b) => ({
    id: b._id,
    billNumber: b.billNumber,
    billDate: b.billDate,
    total: b.total,
    status: b.status,
    customer: b.customerId ? { name: b.customerId.name } : null,
  }));

  const recentPayments = recentPaymentsData.map((p) => ({
    id: p._id,
    receiptNumber: p.receiptNumber,
    amount: p.amount,
    mode: p.mode,
    paymentDate: p.paymentDate,
    customer: p.customerId ? { name: p.customerId.name } : null,
    isCancelled: p.isCancelled,
  }));

  return {
    todayRevenue,
    todayOrders,
    monthlyCollection,
    outstanding,
    totalCustomers,
    pendingCustomers,
    topCustomers,
    recentBills,
    recentPayments,
    salesSeries,
  };
};

module.exports = { getDashboard };
