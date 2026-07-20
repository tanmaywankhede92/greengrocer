const paymentRepository = require('../repositories/paymentRepository');
const ledgerRepository = require('../repositories/ledgerRepository');
const customerRepository = require('../repositories/customerRepository');
const { generateReceiptNumber } = require('../helpers/sequenceGenerator');

const listPayments = async (customerId, query) => {
  return paymentRepository.findPayments(customerId, query);
};

const createPayment = async ({ customerId, amount, mode, reference, notes, paymentDate }, userId) => {
  const customer = await customerRepository.findById(customerId);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }

  const receiptNumber = await generateReceiptNumber();

  const payment = await paymentRepository.createPayment({
    receiptNumber,
    customerId,
    amount,
    mode: mode || 'cash',
    reference: reference || '',
    notes: notes || '',
    paymentDate: new Date(paymentDate),
    createdBy: userId,
  });

  await ledgerRepository.createEntry({
    customerId,
    entryType: 'payment',
    entryDate: new Date(paymentDate),
    description: `Payment ${receiptNumber}`,
    debit: 0,
    credit: amount,
    referenceId: payment._id,
    createdBy: userId,
  });

  return { id: payment._id, receiptNumber };
};

module.exports = { listPayments, createPayment };
