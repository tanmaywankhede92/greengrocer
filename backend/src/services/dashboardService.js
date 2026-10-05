const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');
const Customer = require('../models/Customer');
const LedgerEntry = require('../models/LedgerEntry');

const DAY_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

const getLocalDateString = (now = new Date(), offsetMinutes = 330) => {
  const localTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);
  const y = localTime.getUTCFullYear();
  const m = String(localTime.getUTCMonth() + 1).padStart(2, '0');
  const d = String(localTime.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
};

const getDashboard = async (clientDateStr, clientTzOffset = 330) => {
  const tzOffsetMinutes = (typeof clientTzOffset === 'number' && !Number.isNaN(clientTzOffset))
    ? clientTzOffset
    : 330;

  let targetDateStr;
  if (clientDateStr && DAY_ONLY.test(String(clientDateStr).trim())) {
    targetDateStr = String(clientDateStr).trim();
  } else {
    targetDateStr = getLocalDateString(new Date(), tzOffsetMinutes);
  }

  const [yearStr, monthStr, dayStr] = targetDateStr.split('-');
  const targetYear = Number(yearStr);
  const targetMonth = Number(monthStr); // 1 to 12
  const targetDay = Number(dayStr); // 1 to 31

  // 1. Day Boundaries (Strict calendar day in local timezone and UTC)
  const utcDayStart = new Date(Date.UTC(targetYear, targetMonth - 1, targetDay, 0, 0, 0, 0));
  const utcDayEnd = new Date(Date.UTC(targetYear, targetMonth - 1, targetDay, 23, 59, 59, 999));
  const localDayStart = new Date(utcDayStart.getTime() - tzOffsetMinutes * 60 * 1000);
  const localDayEnd = new Date(utcDayEnd.getTime() - tzOffsetMinutes * 60 * 1000);

  // 2. Month Boundaries (Strict calendar month: 1st 00:00:00 to last day 23:59:59.999)
  const daysInMonth = new Date(Date.UTC(targetYear, targetMonth, 0)).getUTCDate();
  const utcMonthStart = new Date(Date.UTC(targetYear, targetMonth - 1, 1, 0, 0, 0, 0));
  const utcMonthEnd = new Date(Date.UTC(targetYear, targetMonth - 1, daysInMonth, 23, 59, 59, 999));
  const localMonthStart = new Date(utcMonthStart.getTime() - tzOffsetMinutes * 60 * 1000);
  const localMonthEnd = new Date(utcMonthEnd.getTime() - tzOffsetMinutes * 60 * 1000);

  // 3. Six Months Window for Sales Chart (Strictly 6 calendar months ending at targetMonth)
  const sixMonthsAgoUTC = new Date(Date.UTC(targetYear, targetMonth - 6, 1, 0, 0, 0, 0));
  const sixMonthsAgoLocal = new Date(sixMonthsAgoUTC.getTime() - tzOffsetMinutes * 60 * 1000);

  const [
    todayBills,
    monthPayments,
    customerList,
    recentBillsData,
    recentPaymentsData,
    monthlySalesData,
    allLedgerBalances,
  ] = await Promise.all([
    Bill.find({
      status: 'active',
      $or: [
        { billDate: { $gte: localDayStart, $lte: localDayEnd } },
        { billDate: { $gte: utcDayStart, $lte: utcDayEnd } },
      ],
    }).lean(),
    Payment.find({
      isCancelled: false,
      $or: [
        { paymentDate: { $gte: localMonthStart, $lte: localMonthEnd } },
        { paymentDate: { $gte: utcMonthStart, $lte: utcMonthEnd } },
      ],
    }).lean(),
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
    Bill.find({
      status: 'active',
      $or: [
        { billDate: { $gte: sixMonthsAgoLocal } },
        { billDate: { $gte: sixMonthsAgoUTC } },
      ],
    })
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

  const toLocalMonthKey = (date) => {
    const local = new Date(date.getTime() + tzOffsetMinutes * 60 * 1000);
    return `${local.getUTCFullYear()}-${String(local.getUTCMonth() + 1).padStart(2, '0')}`;
  };

  const byMonth = {};
  monthlySalesData.forEach((b) => {
    const d = new Date(b.billDate);
    const key = toLocalMonthKey(d);
    byMonth[key] = (byMonth[key] || 0) + b.total;
  });

  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const salesSeries = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date(Date.UTC(targetYear, targetMonth - 1 - i, 1));
    const y = d.getUTCFullYear();
    const m = d.getUTCMonth();
    const key = `${y}-${String(m + 1).padStart(2, '0')}`;
    salesSeries.push({ month: monthNames[m], sales: byMonth[key] || 0 });
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
