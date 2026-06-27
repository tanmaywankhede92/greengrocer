const express = require('express');
const router = express.Router();

router.use('/auth', require('./authRoutes'));
router.use('/dashboard', require('./dashboardRoutes'));
router.use('/customers', require('./customerRoutes'));
router.use('/products', require('./productRoutes'));
router.use('/rates', require('./rateRoutes'));
router.use('/bills', require('./billRoutes'));
router.use('/payments', require('./paymentRoutes'));
router.use('/ledger', require('./ledgerRoutes'));
router.use('/statements', require('./statementRoutes'));
router.use('/settings', require('./settingsRoutes'));

module.exports = router;
