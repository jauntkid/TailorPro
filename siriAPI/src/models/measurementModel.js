const mongoose = require('mongoose');

const measurementSchema = new mongoose.Schema(
    {
        customer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Customer',
            required: [true, 'Please add a customer'],
        },
        category: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Category',
            required: [true, 'Please add a category'],
        },
        // Dynamic measurements stored as key-value pairs
        measurements: {
            type: Map,
            of: String,
            default: {},
        },
        notes: {
            type: String,
        },
        // Reference to the user who took the measurements
        measuredBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Measurement', measurementSchema); 