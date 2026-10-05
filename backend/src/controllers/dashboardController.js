const dashboardService = require('../services/dashboardService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');

const get = asyncHandler(async (req, res) => {
  const { date, tzOffset } = req.query;
  const offset = tzOffset !== undefined && tzOffset !== '' ? Number(tzOffset) : 330;
  const data = await dashboardService.getDashboard(date, offset);
  ApiResponse.success(res, data);
});

module.exports = { get };
