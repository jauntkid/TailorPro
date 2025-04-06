const mongoose = require('mongoose');

// Define a schema for measurement ranges
const measurementRangeSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true,
        },
        unit: {
            type: String,
            default: 'in', // inches by default
            enum: ['in', 'cm', 'mm'],
        },
        minValue: {
            type: Number,
            default: 0,
        },
        maxValue: {
            type: Number,
            default: 100,
        },
    },
    { _id: false } // Don't generate IDs for subdocuments
);

const productSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Please add a name'],
            trim: true,
        },
        description: {
            type: String,
            trim: true,
        },
        price: {
            type: Number,
            required: [true, 'Please add a price'],
            default: 0,
        },
        category: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Category',
            required: [true, 'Please add a category'],
        },
        image: {
            type: String,
            default: 'default-product.jpg',
        },
        icon: {
            type: String,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        measurements: [measurementRangeSchema], // Array of required measurements with ranges
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model('Product', productSchema); 