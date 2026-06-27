const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { createCustomerSchema, updateCustomerSchema } = require('../validators/customerValidator');

router.use(authenticate);

router.get('/', customerController.list);
router.get('/:id', customerController.getById);
router.post('/', validate(createCustomerSchema), customerController.create);
router.put('/:id', validate(updateCustomerSchema), customerController.update);
router.delete('/:id', customerController.remove);

module.exports = router;
