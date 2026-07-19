const Counter = require('../models/Counter');

const getNextSequence = async (name) => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const yearMonth = `${yy}${mm}`;
  const docId = `${name}_${yearMonth}`;

  const counter = await Counter.findOneAndUpdate(
    { _id: docId },
    { $inc: { seq: 1 } },
    { new: true },
  );
  if (counter) return counter.seq.toString().padStart(4, '0');

  try {
    await Counter.create({ _id: docId, seq: 1, yearMonth });
  } catch (error) {
    if (error.code === 11000) {
      const retried = await Counter.findOneAndUpdate(
        { _id: docId },
        { $inc: { seq: 1 } },
        { new: true },
      );
      if (retried) return retried.seq.toString().padStart(4, '0');
    }
    throw error;
  }

  return '0001';
};

const generateBillNumber = async (prefix) => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const seq = await getNextSequence('bill_number');
  return `${prefix || 'RE'}-${yy}${mm}-${seq}`;
};

const generateReceiptNumber = async () => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const seq = await getNextSequence('receipt_number');
  return `RCPT-${yy}${mm}-${seq}`;
};

module.exports = { generateBillNumber, generateReceiptNumber };
