const BillItem = require('../models/BillItem');

const findByBillId = async (billId) => {
  return BillItem.find({ billId }).lean();
};

module.exports = { findByBillId };
