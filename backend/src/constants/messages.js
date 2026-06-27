module.exports = {
  AUTH: {
    REGISTER_SUCCESS: 'Account created successfully',
    LOGIN_SUCCESS: 'Login successful',
    LOGOUT_SUCCESS: 'Logged out successfully',
    TOKEN_REFRESHED: 'Token refreshed successfully',
    INVALID_CREDENTIALS: 'Invalid email or password',
    EMAIL_EXISTS: 'An account with this email already exists',
    UNAUTHORIZED: 'Authentication required',
    FORBIDDEN: 'You do not have permission to perform this action',
    TOKEN_EXPIRED: 'Token has expired',
    INVALID_TOKEN: 'Invalid token',
  },
  CUSTOMER: {
    CREATED: 'Customer created successfully',
    UPDATED: 'Customer updated successfully',
    DELETED: 'Customer removed successfully',
    NOT_FOUND: 'Customer not found',
    MOBILE_EXISTS: 'Mobile number already exists',
  },
  PRODUCT: {
    CREATED: 'Product created successfully',
    UPDATED: 'Product updated successfully',
    NOT_FOUND: 'Product not found',
  },
  RATE: {
    SAVED: 'Rate saved successfully',
  },
  BILL: {
    CREATED: 'Bill generated successfully',
    CANCELLED: 'Bill cancelled successfully',
    NOT_FOUND: 'Bill not found',
    ALREADY_CANCELLED: 'Bill is already cancelled',
    NO_ITEMS: 'At least one item is required',
  },
  PAYMENT: {
    CREATED: 'Payment recorded successfully',
    NOT_FOUND: 'Payment not found',
  },
  SETTINGS: {
    UPDATED: 'Settings updated successfully',
  },
  VALIDATION: {
    ERROR: 'Validation error',
  },
  SERVER: {
    ERROR: 'Internal server error',
  },
};
