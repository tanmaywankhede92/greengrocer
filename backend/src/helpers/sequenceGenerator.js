const Counter = require('../models/Counter');

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const getNextSequence = async (name, retries = 3) => {
  const now = new Date();
  const yy = now.getFullYear().toString().slice(-2);
  const mm = (now.getMonth() + 1).toString().padStart(2, '0');
  const yearMonth = `${yy}${mm}`;
  const docId = `${name}_${yearMonth}`;

  while (retries > 0) {
    try {
      const counter = await Counter.findOneAndUpdate(
        { _id: docId },
        { $inc: { seq: 1 }, $setOnInsert: { yearMonth } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      );
      return counter.seq.toString().padStart(4, '0');
    } catch (error) {
      if (error.code !== 11000 || retries <= 1) throw error;
      retries--;
      await sleep(100);
    }
  }
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
