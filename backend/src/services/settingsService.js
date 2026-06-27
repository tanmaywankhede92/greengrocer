const settingsRepository = require('../repositories/settingsRepository');

const getSettings = async () => {
  return settingsRepository.findSettings();
};

const updateSettings = async (data) => {
  const settings = await settingsRepository.updateSettings(data);
  return settings;
};

module.exports = { getSettings, updateSettings };
