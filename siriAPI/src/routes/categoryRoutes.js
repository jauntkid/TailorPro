const express = require('express');
const {
    getCategories,
    getCategory,
    createCategory,
    updateCategory,
    deleteCategory,
    getCategoryProducts
} = require('../controllers/categoryController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

router.route('/')
    .get(getCategories)
    .post(admin, createCategory);

router.route('/:id')
    .get(getCategory)
    .put(admin, updateCategory)
    .delete(admin, deleteCategory);

router.get('/:id/products', getCategoryProducts);

module.exports = router; 