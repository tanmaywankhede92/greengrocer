const rateService = require('../services/rateService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const messages = require('../constants/messages');

const getByDate = asyncHandler(async (req, res) => {
  const rates = await rateService.getRatesByDate(req.query.date);
  ApiResponse.success(res, rates);
});

const upsert = asyncHandler(async (req, res) => {
  await rateService.upsertRate({
    productId: req.body.productId,
    rate: req.body.rate,
    rateDate: req.body.rateDate,
    userId: req.user.id,
  });
  ApiResponse.success(res, null, messages.RATE.SAVED);
});

const getHistory = asyncHandler(async (req, res) => {
  const history = await rateService.getRateHistory(req.params.productId, parseInt(req.query.limit, 10) || 60);
  ApiResponse.success(res, history);
});

module.exports = { getByDate, upsert, getHistory };
