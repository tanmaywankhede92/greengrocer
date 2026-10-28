const app = require('../app');
const config = require('./config');
const connectDatabase = require('./config/database');
const logger = require('./helpers/logger');
const BusinessSetting = require('./models/BusinessSetting');
const Bill = require('./models/Bill');
const Payment = require('./models/Payment');
const Customer = require('./models/Customer');
const Product = require('./models/Product');
const DailyRate = require('./models/DailyRate');

const startServer = async () => {
  await connectDatabase();

  await initDefaults();

  // Ensure high-performance indexes are built asynchronously
  Promise.all([
    Bill.init(),
    Payment.init(),
    Customer.init(),
    Product.init(),
    DailyRate.init(),
  ]).catch((err) => logger.warn('Index build warning:', err.message));

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
