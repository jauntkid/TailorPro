const express = require('express');
const {
    getInvoices,
    getInvoice,
    createInvoice,
    updateInvoice,
    deleteInvoice,
    addPayment,
    removePayment
} = require('../controllers/invoiceController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

router.route('/')
    .get(getInvoices)
    .post(createInvoice);

router.route('/:id')
    .get(getInvoice)
    .put(updateInvoice)
    .delete(admin, deleteInvoice);

router.route('/:id/payments')
    .post(addPayment);

router.route('/:id/payments/:paymentId')
    .delete(admin, removePayment);

module.exports = router; 