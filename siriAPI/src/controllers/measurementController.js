const Measurement = require('../models/measurementModel');
const Customer = require('../models/customerModel');
const Category = require('../models/categoryModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all measurements
 * @route   GET /api/measurements
 * @access  Private
 */
const getMeasurements = asyncHandler(async (req, res) => {
    // Build query
    let query = {};

    // Filter by customer
    if (req.query.customer) {
        query.customer = req.query.customer;
    }

    // Filter by category
    if (req.query.category) {
        query.category = req.query.category;
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Measurement.countDocuments(query);

    // Execute query
    const measurements = await Measurement.find(query)
        .populate('customer', 'name phone')
        .populate('category', 'title')
        .populate('measuredBy', 'name')
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
        count: measurements.length,
        pagination,
        total,
        data: measurements
    });
});

/**
 * @desc    Get single measurement
 * @route   GET /api/measurements/:id
 * @access  Private
 */
const getMeasurement = asyncHandler(async (req, res) => {
    const measurement = await Measurement.findById(req.params.id)
        .populate('customer', 'name phone')
        .populate('category', 'title requiredMeasurements')
        .populate('measuredBy', 'name');

    if (!measurement) {
        throw new ErrorResponse(`Measurement not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: measurement
    });
});

/**
 * @desc    Create new measurement
 * @route   POST /api/measurements
 * @access  Private
 */
const createMeasurement = asyncHandler(async (req, res) => {
    const { customer, category, measurements, notes } = req.body;

    // Check if customer exists
    const customerExists = await Customer.findById(customer);

    if (!customerExists) {
        throw new ErrorResponse(`Customer not found with id of ${customer}`, 404);
    }

    // Check if category exists
    const categoryExists = await Category.findById(category);

    if (!categoryExists) {
        throw new ErrorResponse(`Category not found with id of ${category}`, 404);
    }

    // Create measurement
    const measurement = await Measurement.create({
        customer,
        category,
        measurements,
        notes,
        measuredBy: req.user.id
    });

    // Add measurement to customer
    customerExists.measurements.push(measurement._id);
    await customerExists.save();

    // Populate fields for response
    const populatedMeasurement = await Measurement.findById(measurement._id)
        .populate('customer', 'name phone')
        .populate('category', 'title')
        .populate('measuredBy', 'name');

    res.status(201).json({
        success: true,
        data: populatedMeasurement
    });
});

/**
 * @desc    Update measurement
 * @route   PUT /api/measurements/:id
 * @access  Private
 */
const updateMeasurement = asyncHandler(async (req, res) => {
    const { measurements, notes } = req.body;

    let measurement = await Measurement.findById(req.params.id);

    if (!measurement) {
        throw new ErrorResponse(`Measurement not found with id of ${req.params.id}`, 404);
    }

    // Update measurement
    measurement = await Measurement.findByIdAndUpdate(
        req.params.id,
        {
            measurements,
            notes,
            measuredBy: req.user.id
        },
        {
            new: true,
            runValidators: true
        }
    )
        .populate('customer', 'name phone')
        .populate('category', 'title')
        .populate('measuredBy', 'name');

    res.status(200).json({
        success: true,
        data: measurement
    });
});

/**
 * @desc    Delete measurement
 * @route   DELETE /api/measurements/:id
 * @access  Private
 */
const deleteMeasurement = asyncHandler(async (req, res) => {
    const measurement = await Measurement.findById(req.params.id);

    if (!measurement) {
        throw new ErrorResponse(`Measurement not found with id of ${req.params.id}`, 404);
    }

    // Remove measurement from customer
    const customer = await Customer.findById(measurement.customer);
    if (customer) {
        customer.measurements = customer.measurements.filter(
            id => id.toString() !== req.params.id
        );
        await customer.save();
    }

    await measurement.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

module.exports = {
    getMeasurements,
    getMeasurement,
    createMeasurement,
    updateMeasurement,
    deleteMeasurement
}; 