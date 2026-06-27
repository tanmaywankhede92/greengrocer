const express = require('express');
const router = express.Router();
const rateController = require('../controllers/rateController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { upsertRateSchema } = require('../validators/rateValidator');

router.use(authenticate);

router.get('/', rateController.getByDate);
router.put('/', validate(upsertRateSchema), rateController.upsert);
router.get('/history/:productId', rateController.getHistory);

module.exports = router;
