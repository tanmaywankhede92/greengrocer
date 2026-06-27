const app = require('../app');
const config = require('./config');
const connectDatabase = require('./config/database');
const logger = require('./helpers/logger');
const BusinessSetting = require('./models/BusinessSetting');

const startServer = async () => {
  await connectDatabase();

  await initDefaults();

  app.listen(config.port, () => {
    logger.info(`Server running on port ${config.port} in ${config.env} mode`);
    logger.info(`Health check: http://localhost:${config.port}/health`);
  });
};

const initDefaults = async () => {
  const existing = await BusinessSetting.findOne();
  if (!existing) {
    await BusinessSetting.create({
      businessName: config.defaultBusinessName,
      invoicePrefix: config.defaultPrefix,
    });
    logger.info('Default business settings created');
  }
};

startServer().catch((error) => {
  logger.error('Failed to start server:', error);
  process.exit(1);
});
