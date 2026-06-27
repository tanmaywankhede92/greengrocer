const Counter = require('../models/Counter');

const getNextSequence = async (name) => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const yearMonth = `${yy}${mm}`;

  const counter = await Counter.findOneAndUpdate(
    { _id: name, yearMonth },
    { $inc: { seq: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );

  return counter.seq.toString().padStart(4, '0');
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
