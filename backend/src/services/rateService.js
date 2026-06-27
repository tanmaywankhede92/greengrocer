const rateRepository = require('../repositories/rateRepository');

const getRatesByDate = async (date) => {
  const rateDate = date ? new Date(date) : new Date();
  rateDate.setUTCHours(0, 0, 0, 0);
  return rateRepository.findByDate(rateDate);
};

const upsertRate = async ({ productId, rate, rateDate, userId }) => {
  const date = new Date(rateDate);
  date.setUTCHours(0, 0, 0, 0);
  await rateRepository.upsertRate({ productId, rate, rateDate: date, createdBy: userId });
};

const getRateHistory = async (productId, limit) => {
  return rateRepository.findHistory(productId, limit);
};

module.exports = { getRatesByDate, upsertRate, getRateHistory };
