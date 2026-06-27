const express = require('express');
const router = express.Router();
const ledgerController = require('../controllers/ledgerController');
const authenticate = require('../middlewares/authenticate');

router.use(authenticate);

router.get('/:customerId', ledgerController.getByCustomer);

module.exports = router;
