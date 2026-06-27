const statementService = require('../services/statementService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');

const getByCustomer = asyncHandler(async (req, res) => {
  const { from, to } = req.query;
  if (!from || !to) {
    return ApiResponse.badRequest(res, 'Both "from" and "to" query parameters are required');
  }
  const statement = await statementService.getStatement(req.params.customerId, { from, to });
  ApiResponse.success(res, statement);
});

module.exports = { getByCustomer };
