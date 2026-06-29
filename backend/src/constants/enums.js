module.exports = {
  APP_ROLES: ['admin', 'staff'],
  PRODUCT_UNITS: ['kg', 'pcs', 'bundle', 'box', 'dozen', 'quintal', 'bag', 'crate'], // allow custom units outside this list
  LEDGER_ENTRY_TYPES: ['opening_balance', 'bill', 'payment', 'adjustment'],
  PAYMENT_MODES: ['cash', 'upi', 'bank_transfer', 'cheque'],
  BILL_STATUSES: ['active', 'cancelled'],
};
