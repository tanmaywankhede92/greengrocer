const ledgerRepository = require('../repositories/ledgerRepository');

const getLedger = async (customerId, range) => {
  const entries = await ledgerRepository.findByCustomer(customerId, range);
  return entries.map((e) => ({
    id: e._id,
    customerId: e.customerId,
    entryType: e.entryType,
    entryDate: e.entryDate,
    description: e.description,
    debit: e.debit,
    credit: e.credit,
    createdAt: e.createdAt,
  }));
};

module.exports = { getLedger };
