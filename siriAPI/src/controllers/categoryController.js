const Category = require('../models/categoryModel');
const Product = require('../models/productModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');

/**
 * @desc    Get all categories
 * @route   GET /api/categories
 * @access  Private
 */
const getCategories = asyncHandler(async (req, res) => {
    const categories = await Category.find().sort({ title: 1 });

    res.status(200).json({
        success: true,
        count: categories.length,
        data: categories
    });
});

/**
 * @desc    Get single category
 * @route   GET /api/categories/:id
 * @access  Private
 */
const getCategory = asyncHandler(async (req, res) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
        throw new ErrorResponse(`Category not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: category
    });
});

/**
 * @desc    Create new category
 * @route   POST /api/categories
 * @access  Private/Admin
 */
const createCategory = asyncHandler(async (req, res) => {
    const { title, icon, gradientColors, requiredMeasurements } = req.body;

    // Check if category with same title already exists
    const existingCategory = await Category.findOne({ title });

    if (existingCategory) {
        throw new ErrorResponse(`Category with title ${title} already exists`, 400);
    }

    // Create category
    const category = await Category.create({
        title,
        icon,
        gradientColors,
        requiredMeasurements
    });

    res.status(201).json({
        success: true,
        data: category
    });
});

/**
 * @desc    Update category
 * @route   PUT /api/categories/:id
 * @access  Private/Admin
 */
const updateCategory = asyncHandler(async (req, res) => {
    const { title, icon, gradientColors, requiredMeasurements } = req.body;

    let category = await Category.findById(req.params.id);

    if (!category) {
        throw new ErrorResponse(`Category not found with id of ${req.params.id}`, 404);
    }

    // If title is being changed, check if it's already in use
    if (title && title !== category.title) {
        const existingCategory = await Category.findOne({ title });

        if (existingCategory) {
            throw new ErrorResponse(`Category with title ${title} already exists`, 400);
        }
    }

    // Update category
    category = await Category.findByIdAndUpdate(
        req.params.id,
        {
            title,
            icon,
            gradientColors,
            requiredMeasurements
        },
        {
            new: true,
            runValidators: true
        }
    );

    res.status(200).json({
        success: true,
        data: category
    });
});

/**
 * @desc    Delete category
 * @route   DELETE /api/categories/:id
 * @access  Private/Admin
 */
const deleteCategory = asyncHandler(async (req, res) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
        throw new ErrorResponse(`Category not found with id of ${req.params.id}`, 404);
    }

    // Check if this category is used by any products
    const products = await Product.find({ category: req.params.id });

    if (products.length > 0) {
        throw new ErrorResponse(`Cannot delete category as it is being used by ${products.length} products`, 400);
    }

    await category.remove();

    res.status(200).json({
        success: true,
        data: {}
    });
});

/**
 * @desc    Get category products
 * @route   GET /api/categories/:id/products
 * @access  Private
 */
const getCategoryProducts = asyncHandler(async (req, res) => {
    const category = await Category.findById(req.params.id);

    if (!category) {
        throw new ErrorResponse(`Category not found with id of ${req.params.id}`, 404);
    }

    const products = await Product.find({ category: req.params.id })
        .sort({ name: 1 });

    res.status(200).json({
        success: true,
        count: products.length,
        data: products
    });
});

module.exports = {
    getCategories,
    getCategory,
    createCategory,
    updateCategory,
    deleteCategory,
    getCategoryProducts
}; 