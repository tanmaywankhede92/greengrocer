const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const authenticate = require('../middlewares/authenticate');
const authorize = require('../middlewares/authorize');
const validate = require('../middlewares/validate');
const { updateSettingsSchema } = require('../validators/settingsValidator');

router.use(authenticate);

router.get('/', settingsController.get);
router.put('/', authorize('admin'), validate(updateSettingsSchema), settingsController.update);

module.exports = router;
