const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { createPaymentSchema } = require('../validators/paymentValidator');

router.use(authenticate);

router.get('/', paymentController.list);
router.post('/', validate(createPaymentSchema), paymentController.create);

module.exports = router;
