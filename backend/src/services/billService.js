const billRepository = require('../repositories/billRepository');
const billItemRepository = require('../repositories/billItemRepository');
const ledgerRepository = require('../repositories/ledgerRepository');
const paymentRepository = require('../repositories/paymentRepository');
const settingsRepository = require('../repositories/settingsRepository');
const customerRepository = require('../repositories/customerRepository');
const { generateBillNumber, generateReceiptNumber } = require('../helpers/sequenceGenerator');
const Bill = require('../models/Bill');
const BillItem = require('../models/BillItem');
const BillAdjustment = require('../models/BillAdjustment');
const Payment = require('../models/Payment');
const LedgerEntry = require('../models/LedgerEntry');

const listBills = async (filters, query) => {
  return billRepository.findBills(filters, query);
};

const getBill = async (id) => {
  const result = await billRepository.findById(id);
  if (!result) {
    const error = new Error('Bill not found');
    error.statusCode = 404;
    throw error;
  }
  return result;
};

const createBill = async ({ customerId, billDate, items, deliveryCharge, notes, paymentAmount, paymentMode }, userId) => {
  const customer = await customerRepository.findById(customerId);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }

  let subtotal = 0;
  items.forEach((item) => {
    subtotal += item.quantity * item.appliedRate;
  });
  const total = subtotal + (deliveryCharge || 0);

  const settings = await settingsRepository.findSettings();
  const prefix = settings?.invoicePrefix || 'RE';
  const paid = paymentAmount || 0;
  const paymentType = paid >= total && paid > 0 ? 'cash' : paid > 0 ? 'partial' : 'credit';

  let lastError;
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const billNumber = await generateBillNumber(prefix);
      const bill = await Bill.create({
        billNumber,
        customerId,
        billDate: new Date(billDate),
        subtotal,
        deliveryCharge: deliveryCharge || 0,
        total,
        paidNow: paid,
        paymentType,
        notes: notes || '',
        status: 'active',
        createdBy: userId,
      });

      const billItemsData = items.map((item) => ({
        billId: bill._id,
        productId: item.productId || null,
        productName: item.productName,
        productNameHindi: item.productNameHindi || '',
        unit: item.unit,
        quantity: item.quantity,
        defaultRate: item.defaultRate || 0,
        appliedRate: item.appliedRate,
        amount: item.quantity * item.appliedRate,
      }));

      await BillItem.create(billItemsData);

      await LedgerEntry.create({
        customerId,
        entryType: 'bill',
        entryDate: new Date(billDate),
        description: `Bill ${billNumber}`,
        debit: total,
        credit: 0,
        referenceId: bill._id,
        createdBy: userId,
      });

      if (paid > 0) {
        const receiptNumber = await generateReceiptNumber();
        await Payment.create({
          receiptNumber,
          customerId,
          amount: paid,
          mode: paymentMode || 'cash',
          paymentDate: new Date(billDate),
          billId: bill._id,
          notes: `Paid with bill ${billNumber}`,
          createdBy: userId,
        });

        await LedgerEntry.create({
          customerId,
          entryType: 'payment',
          entryDate: new Date(billDate),
          description: `Payment ${receiptNumber}`,
          debit: 0,
          credit: paid,
          referenceId: bill._id,
          createdBy: userId,
        });
      }

      return { id: bill._id, billNumber: bill.billNumber };
    } catch (error) {
      lastError = error;
      if (error.code === 11000) {
        continue;
      }
      if (error.name === 'ValidationError') {
        throw error;
      }
      throw error;
    }
  }

  throw lastError || new Error('Failed to create bill after multiple attempts');
};

const cancelBill = async (billId, userId) => {
  const result = await billRepository.findById(billId);
  if (!result || !result.bill) {
    const error = new Error('Bill not found');
    error.statusCode = 404;
    throw error;
  }

  if (result.bill.status === 'cancelled') {
    const error = new Error('Bill is already cancelled');
    error.statusCode = 400;
    throw error;
  }

  const { bill } = result;

  try {
    await Bill.findByIdAndUpdate(billId, { status: 'cancelled' });

    await LedgerEntry.create({
      customerId: bill.customerId,
      entryType: 'adjustment',
      entryDate: new Date(),
      description: `Cancelled bill ${bill.billNumber}`,
      debit: 0,
      credit: bill.total,
      referenceId: bill._id,
      createdBy: userId,
    });

    if (bill.paidNow > 0) {
      await Payment.findOneAndUpdate(
        { billId, isCancelled: false },
        { isCancelled: true },
      );

      await LedgerEntry.create({
        customerId: bill.customerId,
        entryType: 'adjustment',
        entryDate: new Date(),
        description: `Reversed payment for cancelled bill ${bill.billNumber}`,
        debit: bill.paidNow,
        credit: 0,
        referenceId: bill._id,
        createdBy: userId,
      });
    }
  } catch (error) {
    throw error;
  }
};

const REASON_LABELS = {
  damaged: 'Damaged',
  missing: 'Missing',
  short_supply: 'Short Supply',
  rate_diff: 'Rate Difference',
  other: 'Other',
};

const adjustBill = async (billId, { amount, reason, note }, userId) => {
  const result = await billRepository.findById(billId);
  if (!result || !result.bill) {
    const error = new Error('Bill not found');
    error.statusCode = 404;
    throw error;
  }

  if (result.bill.status === 'cancelled') {
    const error = new Error('Cannot adjust a cancelled bill');
    error.statusCode = 400;
    throw error;
  }

  const { bill } = result;
  const totalAdjusted = result.adjustments.reduce((sum, a) => sum + a.amount, 0);
  const remaining = bill.total - totalAdjusted;

  if (amount > remaining) {
    const error = new Error(`Adjustment exceeds bill amount. Maximum adjustable: ${remaining}`);
    error.statusCode = 400;
    throw error;
  }

  const reasonLabel = REASON_LABELS[reason] || reason;
  const description = `Adjustment for ${bill.billNumber}: ${reasonLabel}${note ? ` - ${note}` : ''}`;

  const adjustment = await BillAdjustment.create({
    billId: bill._id,
    customerId: bill.customerId,
    amount,
    reason,
    note: note || '',
    adjustmentDate: new Date(),
    createdBy: userId,
  });

  await LedgerEntry.create({
    customerId: bill.customerId,
    entryType: 'adjustment',
    entryDate: new Date(),
    description,
    debit: 0,
    credit: amount,
    referenceId: bill._id,
    createdBy: userId,
  });

  return { id: adjustment._id, amount, reason, note: note || '' };
};

module.exports = { listBills, getBill, createBill, cancelBill, adjustBill };
