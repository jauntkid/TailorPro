const express = require('express');
const userRoutes = require('./userRoutes');
const customerRoutes = require('./customerRoutes');
const categoryRoutes = require('./categoryRoutes');
const productRoutes = require('./productRoutes');
const measurementRoutes = require('./measurementRoutes');
const orderRoutes = require('./orderRoutes');
const invoiceRoutes = require('./invoiceRoutes');

const router = express.Router();

// API routes
router.use('/users', userRoutes);
router.use('/customers', customerRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/measurements', measurementRoutes);
router.use('/orders', orderRoutes);
router.use('/invoices', invoiceRoutes);

// API health check
router.get('/health', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'API is up and running',
        timestamp: new Date().toISOString(),
    });
});

module.exports = router; 