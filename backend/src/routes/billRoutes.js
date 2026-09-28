const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const authenticate = require('../middlewares/authenticate');
const validate = require('../middlewares/validate');
const { createBillSchema, adjustBillSchema, saveDraftSchema } = require('../validators/billValidator');

router.use(authenticate);

// Draft routes MUST come before /:id routes
router.get('/drafts', billController.listDrafts);
router.get('/drafts/:id', billController.getDraftById);
router.post('/drafts', validate(saveDraftSchema), billController.saveDraft);
router.delete('/drafts/:id', billController.discardDraft);

router.get('/', billController.list);
router.get('/:id', billController.getById);
router.post('/', validate(createBillSchema), billController.create);
router.post('/:id/cancel', billController.cancel);
router.put('/:id/adjust', validate(adjustBillSchema), billController.adjust);

module.exports = router;
