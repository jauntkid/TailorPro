const Order = require('../models/orderModel');
const Customer = require('../models/customerModel');
const Product = require('../models/productModel');
const Measurement = require('../models/measurementModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all orders
 * @route   GET /api/orders
 * @access  Private
 */
const getOrders = asyncHandler(async (req, res) => {
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

    // Filter by priority
    if (req.query.priority) {
        query.priority = req.query.priority;
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

    // Search by order number
    if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        query.orderNumber = searchRegex;
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Order.countDocuments(query);

    // Execute query
    const orders = await Order.find(query)
        .populate('customer', 'name phone')
        .populate({
            path: 'items.product',
            select: 'name price category',
            populate: {
                path: 'category',
                select: 'title'
            }
        })
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
        count: orders.length,
        pagination,
        total,
        data: orders
    });
});

/**
 * @desc    Get single order
 * @route   GET /api/orders/:id
 * @access  Private
 */
const getOrder = asyncHandler(async (req, res) => {
    const order = await Order.findById(req.params.id)
        .populate('customer', 'name phone email address')
        .populate({
            path: 'items.product',
            select: 'name price category',
            populate: {
                path: 'category',
                select: 'title'
            }
        })
        .populate('items.measurements')
        .populate('createdBy', 'name')
        .populate('updatedBy', 'name')
        .populate('invoice');

    if (!order) {
        throw new ErrorResponse(`Order not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: order
    });
});

/**
 * @desc    Create new order
 * @route   POST /api/orders
 * @access  Private
 */
const createOrder = asyncHandler(async (req, res) => {
    const { customer, items, status, dueDate, priority, notes, photos, createdBy } = req.body;

    // Check if customer exists
    const customerExists = await Customer.findById(customer);

    if (!customerExists) {
        throw new ErrorResponse(`Customer not found with id of ${customer}`, 404);
    }

    // Validate items
    if (!items || items.length === 0) {
        throw new ErrorResponse('At least one item is required', 400);
    }

    // Validate each item
    for (const item of items) {
        // Check if product exists
        const product = await Product.findById(item.product);

        if (!product) {
            throw new ErrorResponse(`Product not found with id of ${item.product}`, 404);
        }

        // If measurement is provided, check if it exists and belongs to the customer
        if (item.measurements) {
            const measurement = await Measurement.findById(item.measurements);

            if (!measurement) {
                throw new ErrorResponse(`Measurement not found with id of ${item.measurements}`, 404);
            }

            if (measurement.customer.toString() !== customer) {
                throw new ErrorResponse(`Measurement does not belong to the customer`, 400);
            }
        }

        // Set price from product if not provided
        if (!item.price) {
            item.price = product.price;
        }
    }

    // Calculate totalAmount
    const totalAmount = items.reduce((total, item) => {
        return total + (item.price * (item.quantity || 1));
    }, 0);

    // Generate orderNumber
    const date = new Date();
    const year = date.getFullYear().toString().slice(-2);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');

    // Find the latest order to increment the sequence
    const latestOrder = await Order.findOne({}, {}, { sort: { 'createdAt': -1 } });

    let sequence = 1;
    if (latestOrder && latestOrder.orderNumber) {
        // Extract the sequence number from the last 4 digits of the existing order number
        const lastSequence = parseInt(latestOrder.orderNumber.slice(-4));
        if (!isNaN(lastSequence)) {
            sequence = lastSequence + 1;
        }
    }

    // Format: ORD-YYMM-SEQUENCE
    const orderNumber = `ORD-${year}${month}-${sequence.toString().padStart(4, '0')}`;

    // Create order with orderNumber and totalAmount
    const order = await Order.create({
        orderNumber,
        customer,
        items,
        status,
        totalAmount,
        dueDate,
        priority,
        notes,
        photos,
        createdBy: createdBy || req.user.id,
        updatedBy: req.user.id
    });

    // Populate fields for response
    const populatedOrder = await Order.findById(order._id)
        .populate('customer', 'name phone')
        .populate({
            path: 'items.product',
            select: 'name price category',
            populate: {
                path: 'category',
                select: 'title'
            }
        })
        .populate('createdBy', 'name');

    res.status(201).json({
        success: true,
        data: populatedOrder
    });
});

/**
 * @desc    Update order
 * @route   PUT /api/orders/:id
 * @access  Private
 */
const updateOrder = asyncHandler(async (req, res) => {
    console.log('=== UPDATE ORDER REQUEST ===');
    console.log('Order ID:', req.params.id);
    console.log('Request body:', JSON.stringify(req.body, null, 2));

    const { items, status, dueDate, priority, notes, photos } = req.body;

    let order = await Order.findById(req.params.id);

    if (!order) {
        console.log('Order not found');
        throw new ErrorResponse(`Order not found with id of ${req.params.id}`, 404);
    }

    console.log('Found existing order:', JSON.stringify(order, null, 2));

    // Validate items if provided
    if (items && items.length > 0) {
        console.log('\nProcessing items:', items.length);
        // Validate each item
        for (const item of items) {
            console.log('\nProcessing item:', JSON.stringify(item, null, 2));

            // Check if product exists
            const product = await Product.findById(item.product);
            console.log('Found product:', product ? product._id : 'Not found');

            if (!product) {
                throw new ErrorResponse(`Product not found with id of ${item.product}`, 404);
            }

            // If measurement is provided, check if it exists and belongs to the customer
            if (item.measurements) {
                const measurement = await Measurement.findById(item.measurements);
                console.log('Found measurement:', measurement ? measurement._id : 'Not found');

                if (!measurement) {
                    throw new ErrorResponse(`Measurement not found with id of ${item.measurements}`, 404);
                }

                if (measurement.customer.toString() !== order.customer.toString()) {
                    console.log('Measurement customer mismatch:', {
                        measurementCustomer: measurement.customer,
                        orderCustomer: order.customer
                    });
                    throw new ErrorResponse(`Measurement does not belong to the customer`, 400);
                }
            }

            // Set price from product if not provided
            if (!item.price) {
                item.price = product.price;
                console.log('Set price from product:', item.price);
            }
        }

        // Calculate totalAmount
        const totalAmount = items.reduce((total, item) => {
            return total + (item.price * (item.quantity || 1));
        }, 0);
        console.log('Calculated total amount:', totalAmount);

        // Update order with new items and total
        order.items = items;
        order.totalAmount = totalAmount;
    }

    // Update other fields if provided
    if (status) {
        console.log('Updating status:', status);
        order.status = status;
    }
    if (dueDate) {
        console.log('Updating due date:', dueDate);
        order.dueDate = dueDate;
    }
    if (priority) {
        console.log('Updating priority:', priority);
        order.priority = priority;
    }
    if (notes !== undefined) {
        console.log('Updating notes');
        order.notes = notes;
    }
    if (photos) {
        console.log('Updating photos');
        order.photos = photos;
    }
    order.updatedBy = req.user.id;

    console.log('\nSaving updated order:', JSON.stringify(order, null, 2));

    // Save the updated order
    await order.save();

    // Populate fields for response
    const populatedOrder = await Order.findById(order._id)
        .populate('customer', 'name phone email address')
        .populate({
            path: 'items.product',
            select: 'name price category',
            populate: {
                path: 'category',
                select: 'title'
            }
        })
        .populate('items.measurements')
        .populate('createdBy', 'name')
        .populate('updatedBy', 'name');

    console.log('\nFinal populated order:', JSON.stringify(populatedOrder, null, 2));

    res.status(200).json({
        success: true,
        data: populatedOrder
    });
});

/**
 * @desc    Update order status
 * @route   PUT /api/orders/:id/status
 * @access  Private
 */
const updateOrderStatus = asyncHandler(async (req, res) => {
    try {
        const { orderId, itemId, newStatus } = req.body;

        if (!orderId || !itemId || !newStatus) {
            return res.status(400).json({
                success: false,
                error: 'Order ID, Item ID, and new status are required',
            });
        }

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found',
            });
        }

        // Find the item in the order
        const itemIndex = order.items.findIndex(item => item._id.toString() === itemId);
        if (itemIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Item not found in order',
            });
        }

        // Ensure the item has a deadline
        if (!order.items[itemIndex].deadline) {
            // If no deadline is set, use the order's dueDate or set a default deadline
            order.items[itemIndex].deadline = order.dueDate || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // Default to 7 days from now
        }

        // Update the item's status
        order.items[itemIndex].status = newStatus;

        // If the item is completed, set the completedAt timestamp
        if (newStatus === 'Completed') {
            order.items[itemIndex].completedAt = new Date();
        }

        // Check all items' statuses
        const allItemsCompleted = order.items.every(item => item.status === 'Completed');
        const allItemsReady = order.items.every(item => item.status === 'Ready');
        const someItemsReady = order.items.some(item => item.status === 'Ready' || item.status === 'Completed');
        const someItemsInProgress = order.items.some(item => item.status === 'In Progress');

        // Update order status based on item statuses
        if (allItemsCompleted) {
            order.status = 'Completed';
        } else if (allItemsReady) {
            order.status = 'Ready';
        } else if (someItemsReady) {
            order.status = 'Partially Ready';
        } else if (someItemsInProgress) {
            order.status = 'In Progress';
        } else {
            order.status = 'New';
        }

        await order.save();

        res.status(200).json({
            success: true,
            data: order,
        });
    } catch (error) {
        console.error('Error updating order status:', error);
        res.status(500).json({
            success: false,
            error: 'Error updating order status',
        });
    }
});

/**
 * @desc    Delete order
 * @route   DELETE /api/orders/:id
 * @access  Private
 */
const deleteOrder = asyncHandler(async (req, res) => {
    const order = await Order.findById(req.params.id);

    if (!order) {
        throw new ErrorResponse(`Order not found with id of ${req.params.id}`, 404);
    }

    // Check if order has an invoice
    if (order.invoice) {
        throw new ErrorResponse('Cannot delete order with an invoice', 400);
    }

    await order.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

module.exports = {
    getOrders,
    getOrder,
    createOrder,
    updateOrder,
    updateOrderStatus,
    deleteOrder
}; 