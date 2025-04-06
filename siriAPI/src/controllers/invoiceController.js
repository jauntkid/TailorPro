const Invoice = require('../models/invoiceModel');
const Order = require('../models/orderModel');
const Customer = require('../models/customerModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all invoices
 * @route   GET /api/invoices
 * @access  Private
 */
const getInvoices = asyncHandler(async (req, res) => {
    // Build query
    let query = {};

    // Filter by customer
    if (req.query.customer) {
        query.customer = req.query.customer;
    }

    // Filter by status
    if (req.query.status) {
        query.status = req.query.status;
    }

    // Filter by due date range
    if (req.query.startDate && req.query.endDate) {
        query.dueDate = {
            $gte: new Date(req.query.startDate),
            $lte: new Date(req.query.endDate)
        };
    } else if (req.query.startDate) {
        query.dueDate = { $gte: new Date(req.query.startDate) };
    } else if (req.query.endDate) {
        query.dueDate = { $lte: new Date(req.query.endDate) };
    }

    // Search by invoice number
    if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        query.invoiceNumber = searchRegex;
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Invoice.countDocuments(query);

    // Execute query
    const invoices = await Invoice.find(query)
        .populate('customer', 'name phone')
        .populate('order', 'orderNumber')
        .populate('createdBy', 'name')
        .sort({ createdAt: -1 })
        .skip(startIndex)
        .limit(limit);

    // Pagination result
    const pagination = {};

    if (endIndex < total) {
        pagination.next = {
            page: page + 1,
            limit
        };
    }

    if (startIndex > 0) {
        pagination.prev = {
            page: page - 1,
            limit
        };
    }

    res.status(200).json({
        success: true,
        count: invoices.length,
        pagination,
        total,
        data: invoices
    });
});

/**
 * @desc    Get single invoice
 * @route   GET /api/invoices/:id
 * @access  Private
 */
const getInvoice = asyncHandler(async (req, res) => {
    const invoice = await Invoice.findById(req.params.id)
        .populate('customer', 'name phone email address')
        .populate({
            path: 'order',
            populate: {
                path: 'items.product',
                select: 'name price'
            }
        })
        .populate('createdBy', 'name');

    if (!invoice) {
        throw new ErrorResponse(`Invoice not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: invoice
    });
});

/**
 * @desc    Create new invoice
 * @route   POST /api/invoices
 * @access  Private
 */
const createInvoice = asyncHandler(async (req, res) => {
    const { order: orderId, dueDate, subtotal, discount, tax, notes } = req.body;

    // Check if order exists
    const order = await Order.findById(orderId)
        .populate('customer');

    if (!order) {
        throw new ErrorResponse(`Order not found with id of ${orderId}`, 404);
    }

    // Check if order already has an invoice
    if (order.invoice) {
        throw new ErrorResponse(`Order already has an invoice`, 400);
    }

    // Calculate total amount
    const totalAmount = (subtotal || order.totalAmount) - (discount || 0) + (tax || 0);

    // Create invoice
    const invoice = await Invoice.create({
        order: orderId,
        customer: order.customer._id,
        dueDate: dueDate || order.dueDate,
        subtotal: subtotal || order.totalAmount,
        discount: discount || 0,
        tax: tax || 0,
        totalAmount,
        notes,
        createdBy: req.user.id
    });

    // Update order with invoice reference
    order.invoice = invoice._id;
    await order.save();

    // Populate fields for response
    const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('customer', 'name phone')
        .populate('order', 'orderNumber')
        .populate('createdBy', 'name');

    res.status(201).json({
        success: true,
        data: populatedInvoice
    });
});

/**
 * @desc    Update invoice
 * @route   PUT /api/invoices/:id
 * @access  Private
 */
const updateInvoice = asyncHandler(async (req, res) => {
    const { dueDate, subtotal, discount, tax, notes } = req.body;

    let invoice = await Invoice.findById(req.params.id);

    if (!invoice) {
        throw new ErrorResponse(`Invoice not found with id of ${req.params.id}`, 404);
    }

    // Calculate total amount if any of the amount fields are updated
    let totalAmount = invoice.totalAmount;
    if (subtotal || discount !== undefined || tax !== undefined) {
        totalAmount = (subtotal || invoice.subtotal) - (discount !== undefined ? discount : invoice.discount) + (tax !== undefined ? tax : invoice.tax);
    }

    // Update invoice
    invoice = await Invoice.findByIdAndUpdate(
        req.params.id,
        {
            dueDate: dueDate || invoice.dueDate,
            subtotal: subtotal || invoice.subtotal,
            discount: discount !== undefined ? discount : invoice.discount,
            tax: tax !== undefined ? tax : invoice.tax,
            totalAmount,
            notes: notes || invoice.notes
        },
        {
            new: true,
            runValidators: true
        }
    )
        .populate('customer', 'name phone')
        .populate('order', 'orderNumber')
        .populate('createdBy', 'name');

    res.status(200).json({
        success: true,
        data: invoice
    });
});

/**
 * @desc    Delete invoice
 * @route   DELETE /api/invoices/:id
 * @access  Private
 */
const deleteInvoice = asyncHandler(async (req, res) => {
    const invoice = await Invoice.findById(req.params.id);

    if (!invoice) {
        throw new ErrorResponse(`Invoice not found with id of ${req.params.id}`, 404);
    }

    // Check if invoice has payments
    if (invoice.payments && invoice.payments.length > 0) {
        throw new ErrorResponse('Cannot delete invoice with payments', 400);
    }

    // Remove invoice reference from order
    const order = await Order.findById(invoice.order);
    if (order) {
        order.invoice = undefined;
        await order.save();
    }

    await invoice.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

/**
 * @desc    Add payment to invoice
 * @route   POST /api/invoices/:id/payments
 * @access  Private
 */
const addPayment = asyncHandler(async (req, res) => {
    const { amount, method, date, transactionId, notes } = req.body;

    if (!amount || !method) {
        throw new ErrorResponse('Amount and payment method are required', 400);
    }

    const invoice = await Invoice.findById(req.params.id);

    if (!invoice) {
        throw new ErrorResponse(`Invoice not found with id of ${req.params.id}`, 404);
    }

    // Create payment object
    const payment = {
        amount,
        method,
        date: date || Date.now(),
        transactionId,
        notes,
        recordedBy: req.user.id
    };

    // Add payment to invoice
    invoice.payments.push(payment);

    // Update amount paid and balance
    invoice.amountPaid = invoice.payments.reduce((total, payment) => total + payment.amount, 0);
    invoice.balance = invoice.totalAmount - invoice.amountPaid;

    // Update status based on payment
    if (invoice.balance <= 0) {
        invoice.status = 'Paid';
    } else if (invoice.amountPaid > 0) {
        invoice.status = 'Partially Paid';
    }

    await invoice.save();

    res.status(200).json({
        success: true,
        data: invoice
    });
});

/**
 * @desc    Remove payment from invoice
 * @route   DELETE /api/invoices/:id/payments/:paymentId
 * @access  Private
 */
const removePayment = asyncHandler(async (req, res) => {
    const invoice = await Invoice.findById(req.params.id);

    if (!invoice) {
        throw new ErrorResponse(`Invoice not found with id of ${req.params.id}`, 404);
    }

    // Find payment
    const payment = invoice.payments.id(req.params.paymentId);

    if (!payment) {
        throw new ErrorResponse(`Payment not found with id of ${req.params.paymentId}`, 404);
    }

    // Remove payment
    payment.remove();

    // Update amount paid and balance
    invoice.amountPaid = invoice.payments.reduce((total, payment) => total + payment.amount, 0);
    invoice.balance = invoice.totalAmount - invoice.amountPaid;

    // Update status based on payment
    if (invoice.amountPaid <= 0) {
        invoice.status = 'Unpaid';
    } else if (invoice.balance > 0) {
        invoice.status = 'Partially Paid';
    } else {
        invoice.status = 'Paid';
    }

    await invoice.save();

    res.status(200).json({
        success: true,
        data: invoice
    });
});

module.exports = {
    getInvoices,
    getInvoice,
    createInvoice,
    updateInvoice,
    deleteInvoice,
    addPayment,
    removePayment
}; 