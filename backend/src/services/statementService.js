const customerRepository = require('../repositories/customerRepository');
const ledgerRepository = require('../repositories/ledgerRepository');

const getStatement = async (customerId, { from, to }) => {
  const customer = await customerRepository.findById(customerId);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }

  const openingBalance = await ledgerRepository.getOpeningBalance(customerId, from);
  const totalOpening = (customer.openingBalance || 0) + openingBalance;

  const entries = await ledgerRepository.findByCustomer(customerId, { from, to });

  let runningBalance = totalOpening;
  const rows = entries.map((e) => {
    runningBalance += e.debit - e.credit;
    return {
      date: e.entryDate,
      type: e.entryType,
      description: e.description,
      debit: e.debit,
      credit: e.credit,
      balance: runningBalance,
    };
  });

  const totalDebit = rows.reduce((s, r) => s + r.debit, 0);
  const totalCredit = rows.reduce((s, r) => s + r.credit, 0);

  return {
    customer: { name: customer.name, mobile: customer.mobile },
    period: { from, to },
    openingBalance: totalOpening,
    closingBalance: runningBalance,
    totalDebit,
    totalCredit,
    rows,
  };
};

module.exports = { getStatement };
