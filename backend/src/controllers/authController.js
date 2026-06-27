const authService = require('../services/authService');
const ApiResponse = require('../helpers/apiResponse');
const asyncHandler = require('../helpers/asyncHandler');
const messages = require('../constants/messages');

const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  ApiResponse.created(res, result, messages.AUTH.REGISTER_SUCCESS);
});

const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  ApiResponse.success(res, result, messages.AUTH.LOGIN_SUCCESS);
});

const refresh = asyncHandler(async (req, res) => {
  const result = await authService.refresh(req.body.refreshToken);
  ApiResponse.success(res, result, messages.AUTH.TOKEN_REFRESHED);
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.user.id);
  ApiResponse.success(res, null, messages.AUTH.LOGOUT_SUCCESS);
});

const getProfile = asyncHandler(async (req, res) => {
  const profile = await authService.getProfile(req.user.id);
  ApiResponse.success(res, profile);
});

module.exports = { register, login, refresh, logout, getProfile };
