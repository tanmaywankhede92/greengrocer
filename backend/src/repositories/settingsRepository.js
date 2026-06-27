const BusinessSetting = require('../models/BusinessSetting');

const findSettings = async () => {
  return BusinessSetting.findOne().lean();
};

const updateSettings = async (data) => {
  const settings = await BusinessSetting.findOne();
  if (!settings) {
    return BusinessSetting.create(data);
  }
  Object.assign(settings, data);
  return settings.save();
};

module.exports = { findSettings, updateSettings };
