const Product = require('../models/productModel');
const Category = require('../models/categoryModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all products
 * @route   GET /api/products
 * @access  Private
 */
const getProducts = asyncHandler(async (req, res) => {
    // Build query
    let query = {};

    // Filter by category
    if (req.query.category) {
        query.category = req.query.category;
    }

    // Filter by active status
    if (req.query.active) {
        query.isActive = req.query.active === 'true';
    }

    // Search by name
    if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        query.name = searchRegex;
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const total = await Product.countDocuments(query);

    // Execute query
    const products = await Product.find(query)
        .populate('category', 'title icon')
        .sort({ name: 1 })
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
        count: products.length,
        pagination,
        total,
        data: products
    });
});

/**
 * @desc    Get single product
 * @route   GET /api/products/:id
 * @access  Private
 */
const getProduct = asyncHandler(async (req, res) => {
    const product = await Product.findById(req.params.id)
        .populate('category', 'title icon requiredMeasurements');

    if (!product) {
        throw new ErrorResponse(`Product not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: product
    });
});

/**
 * @desc    Create new product
 * @route   POST /api/products
 * @access  Private/Admin
 */
const createProduct = asyncHandler(async (req, res) => {
    const { name, description, price, category, image, icon, isActive } = req.body;

    // Check if category exists
    const categoryExists = await Category.findById(category);

    if (!categoryExists) {
        throw new ErrorResponse(`Category not found with id of ${category}`, 404);
    }

    // Create product
    const product = await Product.create({
        name,
        description,
        price,
        category,
        image,
        icon,
        isActive
    });

    res.status(201).json({
        success: true,
        data: product
    });
});

/**
 * @desc    Update product
 * @route   PUT /api/products/:id
 * @access  Private/Admin
 */
const updateProduct = asyncHandler(async (req, res) => {
    const { name, description, price, category, image, icon, isActive } = req.body;

    let product = await Product.findById(req.params.id);

    if (!product) {
        throw new ErrorResponse(`Product not found with id of ${req.params.id}`, 404);
    }

    // If category is changing, check if new category exists
    if (category && category !== product.category.toString()) {
        const categoryExists = await Category.findById(category);

        if (!categoryExists) {
            throw new ErrorResponse(`Category not found with id of ${category}`, 404);
        }
    }

    // Update product
    product = await Product.findByIdAndUpdate(
        req.params.id,
        {
            name,
            description,
            price,
            category,
            image,
            icon,
            isActive
        },
        {
            new: true,
            runValidators: true
        }
    ).populate('category', 'title icon');

    res.status(200).json({
        success: true,
        data: product
    });
});

/**
 * @desc    Delete product
 * @route   DELETE /api/products/:id
 * @access  Private/Admin
 */
const deleteProduct = asyncHandler(async (req, res) => {
    const product = await Product.findById(req.params.id);

    if (!product) {
        throw new ErrorResponse(`Product not found with id of ${req.params.id}`, 404);
    }

    await product.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

module.exports = {
    getProducts,
    getProduct,
    createProduct,
    updateProduct,
    deleteProduct
}; 