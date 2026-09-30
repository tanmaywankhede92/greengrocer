const Counter = require('../models/Counter');

const getNextSequence = async (name, { monthly = false } = {}) => {
  let docId = name;
  let yearMonth;
  if (monthly) {
    const now = new Date();
    const yy = now.getFullYear().toString().slice(-2);
    const mm = (now.getMonth() + 1).toString().padStart(2, '0');
    yearMonth = `${yy}${mm}`;
    docId = `${name}_${yearMonth}`;
  }

  const counter = await Counter.findOneAndUpdate(
    { _id: docId },
    { $inc: { seq: 1 } },
    { new: true },
  );
  if (counter) return counter.seq;

  try {
    const createData = { _id: docId, seq: 1 };
    if (yearMonth) createData.yearMonth = yearMonth;
    await Counter.create(createData);
  } catch (error) {
    if (error.code === 11000) {
      const retried = await Counter.findOneAndUpdate(
        { _id: docId },
        { $inc: { seq: 1 } },
        { new: true },
      );
      if (retried) return retried.seq;
    }
    throw error;
  }

  return 1;
};

const generateBillNumber = async (prefix = '') => {
  const seq = await getNextSequence('bill_number', { monthly: false });
  const rawPrefix = prefix !== undefined && prefix !== null ? String(prefix).trim() : '';
  if (!rawPrefix) {
    return seq.toString().padStart(4, '0');
  }
  const sep = rawPrefix.endsWith('-') ? '' : '-';
  return `${rawPrefix}${sep}${seq.toString().padStart(4, '0')}`;
};

const generateInvoiceNumber = async (prefix = 'INV') => {
  const seq = await getNextSequence('invoice_number', { monthly: false });
  const rawPrefix = prefix !== undefined && prefix !== null ? String(prefix).trim() : 'INV';
  const cleanPrefix = rawPrefix || 'INV';
  const sep = cleanPrefix.endsWith('-') ? '' : '-';
  return `${cleanPrefix}${sep}${seq.toString().padStart(4, '0')}`;
};

const generateReceiptNumber = async () => {
  const seq = await getNextSequence('receipt_number', { monthly: false });
  return `INV-${seq.toString().padStart(4, '0')}`;
};

const generateDraftId = async () => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const seq = await getNextSequence('draft_id', { monthly: true });
  return `DFT-${yy}${mm}-${seq.toString().padStart(4, '0')}`;
};

module.exports = { generateBillNumber, generateInvoiceNumber, generateReceiptNumber, generateDraftId };
