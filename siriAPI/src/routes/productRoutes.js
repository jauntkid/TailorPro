const express = require('express');
const {
    getProducts,
    getProduct,
    createProduct,
    updateProduct,
    deleteProduct
} = require('../controllers/productController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

router.route('/')
    .get(getProducts)
    .post(admin, createProduct);

router.route('/:id')
    .get(getProduct)
    .put(admin, updateProduct)
    .delete(admin, deleteProduct);

module.exports = router; 