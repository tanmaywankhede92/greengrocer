const express = require('express');
const router = express.Router();
const statementController = require('../controllers/statementController');
const authenticate = require('../middlewares/authenticate');

router.use(authenticate);

router.get('/:customerId', statementController.getByCustomer);

module.exports = router;
