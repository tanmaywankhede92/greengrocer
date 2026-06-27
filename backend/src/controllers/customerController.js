const customerService = require('../services/customerService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const { getPagination, getSort, buildMeta } = require('../helpers/pagination');
const messages = require('../constants/messages');

const list = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const sort = getSort(req.query, 'name', 'asc');
  const { customers, total } = await customerService.listCustomers({
    search: req.query.search,
    page, limit, skip, sort,
  });
  ApiResponse.paginated(res, customers, buildMeta(total, page, limit));
});

const getById = asyncHandler(async (req, res) => {
  const customer = await customerService.getCustomer(req.params.id);
  ApiResponse.success(res, customer);
});

const create = asyncHandler(async (req, res) => {
  const result = await customerService.createCustomer(req.body, req.user.id);
  ApiResponse.created(res, result, messages.CUSTOMER.CREATED);
});

const update = asyncHandler(async (req, res) => {
  await customerService.updateCustomer(req.params.id, req.body);
  ApiResponse.success(res, null, messages.CUSTOMER.UPDATED);
});

const remove = asyncHandler(async (req, res) => {
  await customerService.deleteCustomer(req.params.id);
  ApiResponse.success(res, null, messages.CUSTOMER.DELETED);
});

module.exports = { list, getById, create, update, remove };
