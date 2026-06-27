const mongoose = require('mongoose');
const billRepository = require('../repositories/billRepository');
const billItemRepository = require('../repositories/billItemRepository');
const ledgerRepository = require('../repositories/ledgerRepository');
const paymentRepository = require('../repositories/paymentRepository');
const settingsRepository = require('../repositories/settingsRepository');
const customerRepository = require('../repositories/customerRepository');
const { generateBillNumber, generateReceiptNumber } = require('../helpers/sequenceGenerator');

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

const createBill = async ({ customerId, billDate, items, discount, notes, paymentAmount, paymentMode }, userId) => {
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
  const total = Math.max(subtotal - (discount || 0), 0);

  const settings = await settingsRepository.findSettings();
  const prefix = settings?.invoicePrefix || 'RE';
  const billNumber = await generateBillNumber(prefix);

  const previousDue = (customer.openingBalance || 0) + (await ledgerRepository.getCustomerBalance(customerId));
  const paid = paymentAmount || 0;
  const newDue = previousDue + total - paid;
  const paymentType = paid >= total && paid > 0 ? 'cash' : paid > 0 ? 'partial' : 'credit';

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const [bill] = await Bill.create(
      [{
        billNumber,
        customerId,
        billDate: new Date(billDate),
        subtotal,
        discount: discount || 0,
        total,
        previousDue,
        paidNow: paid,
        newDue,
        paymentType,
        notes: notes || '',
        status: 'active',
        createdBy: userId,
      }],
      { session },
    );

    const billItemsData = items.map((item) => ({
      billId: bill._id,
      productId: item.productId || null,
      productName: item.productName,
      unit: item.unit,
      quantity: item.quantity,
      defaultRate: item.defaultRate || 0,
      appliedRate: item.appliedRate,
      amount: item.quantity * item.appliedRate,
    }));

    await BillItem.create(billItemsData, { session });

    await LedgerEntry.create(
      [{
        customerId,
        entryType: 'bill',
        entryDate: new Date(billDate),
        description: `Bill ${billNumber}`,
        debit: total,
        credit: 0,
        referenceId: bill._id,
        createdBy: userId,
      }],
      { session },
    );

    if (paid > 0) {
      const receiptNumber = await generateReceiptNumber();
      await Payment.create(
        [{
          receiptNumber,
          customerId,
          amount: paid,
          mode: paymentMode || 'cash',
          paymentDate: new Date(billDate),
          billId: bill._id,
          notes: `Paid with bill ${billNumber}`,
          createdBy: userId,
        }],
        { session },
      );

      await LedgerEntry.create(
        [{
          customerId,
          entryType: 'payment',
          entryDate: new Date(billDate),
          description: `Payment ${receiptNumber}`,
          debit: 0,
          credit: paid,
          referenceId: bill._id,
          createdBy: userId,
        }],
        { session },
      );
    }

    await session.commitTransaction();
    return { id: bill._id };
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
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
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    await Bill.findByIdAndUpdate(billId, { status: 'cancelled' }, { session });

    await LedgerEntry.create(
      [{
        customerId: bill.customerId,
        entryType: 'adjustment',
        entryDate: new Date(),
        description: `Cancelled bill ${bill.billNumber}`,
        debit: 0,
        credit: bill.total,
        referenceId: bill._id,
        createdBy: userId,
      }],
      { session },
    );

    if (bill.paidNow > 0) {
      await Payment.findOneAndUpdate(
        { billId, isCancelled: false },
        { isCancelled: true },
        { session },
      );

      await LedgerEntry.create(
        [{
          customerId: bill.customerId,
          entryType: 'adjustment',
          entryDate: new Date(),
          description: `Reversed payment for cancelled bill ${bill.billNumber}`,
          debit: bill.paidNow,
          credit: 0,
          referenceId: bill._id,
          createdBy: userId,
        }],
        { session },
      );
    }

    await session.commitTransaction();
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

const Bill = require('../models/Bill');
const BillItem = require('../models/BillItem');
const Payment = require('../models/Payment');
const LedgerEntry = require('../models/LedgerEntry');

module.exports = { listBills, getBill, createBill, cancelBill };
