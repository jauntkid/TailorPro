const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Please add a name'],
            trim: true,
        },
        phone: {
            type: String,
            required: [true, 'Please add a phone number'],
            trim: true,
        },
        email: {
            type: String,
            match: [
                /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
                'Please add a valid email',
            ],
            lowercase: true,
            sparse: true,
        },
        address: {
            type: String,
            trim: true,
        },
        referral: {
            type: String,
            trim: true,
        },
        notes: {
            type: String,
        },
        profileImage: {
            type: String,
            default: 'default-customer.jpg',
        },
        // Store reference to measurement documents
        measurements: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Measurement',
            },
        ],
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// Virtual field for orders
customerSchema.virtual('orders', {
    ref: 'Order',
    localField: '_id',
    foreignField: 'customer',
    justOne: false,
});

module.exports = mongoose.model('Customer', customerSchema); 