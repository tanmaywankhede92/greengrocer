const ledgerService = require('../services/ledgerService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');

const getByCustomer = asyncHandler(async (req, res) => {
  const entries = await ledgerService.getLedger(req.params.customerId, {
    from: req.query.from,
    to: req.query.to,
  });
  ApiResponse.success(res, entries);
});

module.exports = { getByCustomer };
