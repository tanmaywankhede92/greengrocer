const paymentService = require('../services/paymentService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const { getPagination, getSort, buildMeta } = require('../helpers/pagination');
const messages = require('../constants/messages');

const list = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const sort = getSort(req.query, 'createdAt', 'desc');
  const { payments, total } = await paymentService.listPayments(req.query.customerId || null, { page, limit, skip, sort });
  ApiResponse.paginated(res, payments, buildMeta(total, page, limit));
});

const create = asyncHandler(async (req, res) => {
  const result = await paymentService.createPayment(req.body, req.user.id);
  ApiResponse.created(res, result, messages.PAYMENT.CREATED);
});

module.exports = { list, create };
