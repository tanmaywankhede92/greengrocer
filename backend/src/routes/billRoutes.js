const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { createBillSchema } = require('../validators/billValidator');

router.use(authenticate);

router.get('/', billController.list);
router.get('/:id', billController.getById);
router.post('/', validate(createBillSchema), billController.create);
router.post('/:id/cancel', billController.cancel);

module.exports = router;
