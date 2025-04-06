const express = require('express');
const {
    getMeasurements,
    getMeasurement,
    createMeasurement,
    updateMeasurement,
    deleteMeasurement
} = require('../controllers/measurementController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

router.route('/')
    .get(getMeasurements)
    .post(createMeasurement);

router.route('/:id')
    .get(getMeasurement)
    .put(updateMeasurement)
    .delete(deleteMeasurement);

module.exports = router; 