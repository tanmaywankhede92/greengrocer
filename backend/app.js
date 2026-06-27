const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./src/config');
const logger = require('./src/helpers/logger');
const errorHandler = require('./src/middlewares/errorHandler');
const { apiLimiter } = require('./src/middlewares/rateLimiter');
const routes = require('./src/routes');

const app = express();

app.use(helmet());
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

if (config.env !== 'test') {
  app.use(morgan('dev', {
    stream: { write: (message) => logger.info(message.trim()) },
  }));
}

app.use('/api', apiLimiter);

app.get('/health', (_req, res) => {
  res.json({
    success: true,
    message: 'Greengrocer API is running',
    environment: config.env,
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/v1', routes);

app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found',
  });
});

app.use(errorHandler);

module.exports = app;
