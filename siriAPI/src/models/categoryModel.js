const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Please add a title'],
            trim: true,
            unique: true,
        },
        icon: {
            type: String,
            default: 'category',
        },
        gradientColors: {
            type: [String],
            default: ['#FF5722', '#F44336'],
        },
        // Required measurements for this category
        requiredMeasurements: [
            {
                type: String,
                trim: true,
            },
        ],
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// Virtual field for products
categorySchema.virtual('products', {
    ref: 'Product',
    localField: '_id',
    foreignField: 'category',
    justOne: false,
});

module.exports = mongoose.model('Category', categorySchema); 