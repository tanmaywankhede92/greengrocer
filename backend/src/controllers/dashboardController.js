const dashboardService = require('../services/dashboardService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');

const get = asyncHandler(async (_req, res) => {
  const data = await dashboardService.getDashboard();
  ApiResponse.success(res, data);
});

module.exports = { get };
