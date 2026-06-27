const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const authenticate = require('../middlewares/authenticate');

router.use(authenticate);

router.get('/', dashboardController.get);

module.exports = router;
