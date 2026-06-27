const settingsService = require('../services/settingsService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const messages = require('../constants/messages');

const get = asyncHandler(async (_req, res) => {
  const settings = await settingsService.getSettings();
  ApiResponse.success(res, settings);
});

const update = asyncHandler(async (req, res) => {
  await settingsService.updateSettings(req.body);
  ApiResponse.success(res, null, messages.SETTINGS.UPDATED);
});

module.exports = { get, update };
