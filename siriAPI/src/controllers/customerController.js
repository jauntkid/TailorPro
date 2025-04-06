const Customer = require('../models/customerModel');
const Order = require('../models/orderModel');
const Measurement = require('../models/measurementModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all customers
 * @route   GET /api/customers
 * @access  Private
 */
const getCustomers = asyncHandler(async (req, res) => {
    // Build query
    let query = {};

    // Search by name or phone
    if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        query = {
            $or: [
                { name: searchRegex },
                { phone: searchRegex },
                { email: searchRegex }
            ]
        };
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Customer.countDocuments(query);

    // Execute query
    const customers = await Customer.find(query)
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
        count: customers.length,
        pagination,
        total,
        data: customers
    });
});

/**
 * @desc    Get single customer
 * @route   GET /api/customers/:id
 * @access  Private
 */
const getCustomer = asyncHandler(async (req, res) => {
    const customer = await Customer.findById(req.params.id)
        .populate('measurements');

    if (!customer) {
        throw new ErrorResponse(`Customer not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: customer
    });
});

/**
 * @desc    Create new customer
 * @route   POST /api/customers
 * @access  Private
 */
const createCustomer = asyncHandler(async (req, res) => {
    const { name, phone, email, address, referral, notes, profileImage } = req.body;

    // Check if customer with same phone number already exists
    const existingCustomer = await Customer.findOne({ phone });

    if (existingCustomer) {
        throw new ErrorResponse(`Customer with phone ${phone} already exists`, 400);
    }

    // Create customer
    const customer = await Customer.create({
        name,
        phone,
        email,
        address,
        referral,
        notes,
        profileImage
    });

    res.status(201).json({
        success: true,
        data: customer
    });
});

/**
 * @desc    Update customer
 * @route   PUT /api/customers/:id
 * @access  Private
 */
const updateCustomer = asyncHandler(async (req, res) => {
    const { name, phone, email, address, referral, notes, profileImage } = req.body;

    let customer = await Customer.findById(req.params.id);

    if (!customer) {
        throw new ErrorResponse(`Customer not found with id of ${req.params.id}`, 404);
    }

    // If phone number is being changed, check if it's already in use
    if (phone && phone !== customer.phone) {
        const existingCustomer = await Customer.findOne({ phone });

        if (existingCustomer) {
            throw new ErrorResponse(`Customer with phone ${phone} already exists`, 400);
        }
    }

    // Update customer
    customer = await Customer.findByIdAndUpdate(
        req.params.id,
        {
            name,
            phone,
            email,
            address,
            referral,
            notes,
            profileImage
        },
        {
            new: true,
            runValidators: true
        }
    );

    res.status(200).json({
        success: true,
        data: customer
    });
});

/**
 * @desc    Delete customer
 * @route   DELETE /api/customers/:id
 * @access  Private
 */
const deleteCustomer = asyncHandler(async (req, res) => {
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
        throw new ErrorResponse(`Customer not found with id of ${req.params.id}`, 404);
    }

    await customer.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

/**
 * @desc    Get customer orders
 * @route   GET /api/customers/:id/orders
 * @access  Private
 */
const getCustomerOrders = asyncHandler(async (req, res) => {
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
        throw new ErrorResponse(`Customer not found with id of ${req.params.id}`, 404);
    }

    const orders = await Order.find({ customer: req.params.id })
        .sort({ createdAt: -1 });

    res.status(200).json({
        success: true,
        count: orders.length,
        data: orders
    });
});

/**
 * @desc    Get customer measurements
 * @route   GET /api/customers/:id/measurements
 * @access  Private
 */
const getCustomerMeasurements = asyncHandler(async (req, res) => {
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
        throw new ErrorResponse(`Customer not found with id of ${req.params.id}`, 404);
    }

    const measurements = await Measurement.find({ customer: req.params.id })
        .populate('category')
        .sort({ createdAt: -1 });

    res.status(200).json({
        success: true,
        count: measurements.length,
        data: measurements
    });
});

module.exports = {
    getCustomers,
    getCustomer,
    createCustomer,
    updateCustomer,
    deleteCustomer,
    getCustomerOrders,
    getCustomerMeasurements
};
