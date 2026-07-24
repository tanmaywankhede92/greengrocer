const productService = require('../services/productService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const messages = require('../constants/messages');

const list = asyncHandler(async (req, res) => {
  const products = await productService.listProducts({
    activeOnly: req.query.activeOnly === 'true',
    search: req.query.search || '',
  });
  ApiResponse.success(res, products);
});

const create = asyncHandler(async (req, res) => {
  const product = await productService.createProduct(req.body);
  ApiResponse.created(res, { id: product._id }, messages.PRODUCT.CREATED);
});

const update = asyncHandler(async (req, res) => {
  await productService.updateProduct(req.params.id, req.body);
  ApiResponse.success(res, null, messages.PRODUCT.UPDATED);
});

const toggle = asyncHandler(async (req, res) => {
  await productService.toggleProduct(req.params.id, req.body.isActive);
  ApiResponse.success(res, null, messages.PRODUCT.UPDATED);
});

const remove = asyncHandler(async (req, res) => {
  await productService.deleteProduct(req.params.id);
  ApiResponse.success(res, null, messages.PRODUCT.DELETED);
});

module.exports = { list, create, update, toggle, remove };
