const customerRepository = require('../repositories/customerRepository');
const ledgerRepository = require('../repositories/ledgerRepository');

const listCustomers = async (query) => {
  return customerRepository.findCustomers(query);
};

const getCustomer = async (id) => {
  const customer = await customerRepository.findById(id);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }

  const ledgerBal = await ledgerRepository.getCustomerBalance(id);
  const currentDue = (customer.openingBalance || 0) + ledgerBal;

  return { ...customer.toObject(), currentDue };
};

const createCustomer = async (data, userId) => {
  const existing = await customerRepository.findByMobile(data.mobile);
  if (existing) {
    const error = new Error('Mobile number already exists');
    error.statusCode = 409;
    throw error;
  }

  const customer = await customerRepository.createCustomer({ ...data, createdBy: userId });

  if (data.openingBalance && data.openingBalance !== 0) {
    await ledgerRepository.createEntry({
      customerId: customer._id,
      entryType: 'opening_balance',
      entryDate: new Date(),
      description: 'Opening balance',
      debit: data.openingBalance > 0 ? data.openingBalance : 0,
      credit: data.openingBalance < 0 ? -data.openingBalance : 0,
      createdBy: userId,
    });
  }

  return { id: customer._id };
};

const updateCustomer = async (id, data) => {
  if (data.mobile) {
    const existing = await customerRepository.findByMobile(data.mobile, id);
    if (existing) {
      const error = new Error('Mobile number already exists');
      error.statusCode = 409;
      throw error;
    }
  }

  const customer = await customerRepository.updateCustomer(id, data);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }

  return customer;
};

const deleteCustomer = async (id) => {
  const customer = await customerRepository.softDelete(id);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }
};

const getCustomerBalance = async (id) => {
  const customer = await customerRepository.findById(id);
  if (!customer) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }
  const balance = await ledgerRepository.getCustomerBalance(id);
  return (customer.openingBalance || 0) + balance;
};

module.exports = { listCustomers, getCustomer, createCustomer, updateCustomer, deleteCustomer, getCustomerBalance };
