const DailyRate = require('../models/DailyRate');

const findByDate = async (rateDate) => {
  const rates = await DailyRate.find({ rateDate }).lean();
  const map = {};
  rates.forEach((r) => {
    map[r.productId.toString()] = { id: r._id, rate: r.rate, rateDate: r.rateDate };
  });
  return map;
};

const upsertRate = async ({ productId, rate, rateDate, createdBy }) => {
  return DailyRate.findOneAndUpdate(
    { productId, rateDate },
    { productId, rate, rateDate, createdBy },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
};

const findHistory = async (productId, limit = 60) => {
  return DailyRate.find({ productId })
    .sort({ rateDate: -1 })
    .limit(limit)
    .lean();
};

module.exports = { findByDate, upsertRate, findHistory };
