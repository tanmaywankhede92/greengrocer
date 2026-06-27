const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { createProductSchema, updateProductSchema, toggleProductSchema } = require('../validators/productValidator');

router.use(authenticate);

router.get('/', productController.list);
router.post('/', validate(createProductSchema), productController.create);
router.put('/:id', validate(updateProductSchema), productController.update);
router.patch('/:id/toggle', validate(toggleProductSchema), productController.toggle);

module.exports = router;
