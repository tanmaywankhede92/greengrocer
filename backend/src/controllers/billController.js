const billService = require('../services/billService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const { getPagination, getSort, buildMeta } = require('../helpers/pagination');
const messages = require('../constants/messages');

const list = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const sort = getSort(req.query, 'createdAt', 'desc');
  const { bills, total } = await billService.listBills(
    {
      search: req.query.search,
      status: req.query.status,
      from: req.query.from,
      to: req.query.to,
    },
    { page, limit, skip, sort },
  );
  ApiResponse.paginated(res, bills, buildMeta(total, page, limit));
});

const getById = asyncHandler(async (req, res) => {
  const result = await billService.getBill(req.params.id);
  ApiResponse.success(res, result);
});

const create = asyncHandler(async (req, res) => {
  const body = { ...req.body };
  delete body._id;
  delete body.id;
  if (body.items && Array.isArray(body.items)) {
    body.items = body.items.map((item) => {
      const { _id, id, ...rest } = item;
      return rest;
    });
  }
  const result = await billService.createBill(body, req.user.id);
  ApiResponse.created(res, result, messages.BILL.CREATED);
});

const update = asyncHandler(async (req, res) => {
  const body = { ...req.body };
  delete body._id;
  delete body.id;
  if (body.items && Array.isArray(body.items)) {
    body.items = body.items.map((item) => {
      const { _id, id, ...rest } = item;
      return rest;
    });
  }
  const result = await billService.updateBill(req.params.id, body, req.user.id);
  ApiResponse.success(res, result, messages.BILL.UPDATED);
});

const remove = asyncHandler(async (req, res) => {
  const result = await billService.deleteBill(req.params.id, req.user.id);
  ApiResponse.success(res, result, messages.BILL.DELETED);
});

const cancel = asyncHandler(async (req, res) => {
  await billService.cancelBill(req.params.id, req.user.id);
  ApiResponse.success(res, null, messages.BILL.CANCELLED);
});

const adjust = asyncHandler(async (req, res) => {
  const result = await billService.adjustBill(req.params.id, req.body, req.user.id);
  ApiResponse.success(res, result, messages.BILL.ADJUSTED);
});

const listDrafts = asyncHandler(async (req, res) => {
  const drafts = await billService.listDrafts(req.query);
  ApiResponse.success(res, drafts);
});

const getDraftById = asyncHandler(async (req, res) => {
  const draft = await billService.getDraft(req.params.id);
  ApiResponse.success(res, draft);
});

const saveDraft = asyncHandler(async (req, res) => {
  const draft = await billService.saveDraft(req.body, req.user?.id);
  ApiResponse.success(res, draft, 'Bill saved as draft');
});

const discardDraft = asyncHandler(async (req, res) => {
  await billService.discardDraft(req.params.id);
  ApiResponse.success(res, null, 'Draft discarded');
});

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  cancel,
  adjust,
  listDrafts,
  getDraftById,
  saveDraft,
  discardDraft,
};
