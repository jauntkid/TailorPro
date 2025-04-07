const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: [true, 'Please add a product'],
    },
    quantity: {
        type: Number,
        required: [true, 'Please add a quantity'],
        default: 1,
    },
    price: {
        type: Number,
        required: [true, 'Please add a price'],
    },
    measurements: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Measurement',
    },
    notes: {
        type: String,
    },
    deadline: {
        type: Date,
        required: [true, 'Please add a deadline for this item'],
    },
    status: {
        type: String,
        enum: ['New', 'In Progress', 'Ready', 'Urgent', 'Completed', 'Cancelled'],
        default: 'New',
    },
    completedAt: {
        type: Date,
    },
});

const orderSchema = new mongoose.Schema(
    {
        orderNumber: {
            type: String,
            required: true,
            unique: true,
        },
        customer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Customer',
            required: [true, 'Please add a customer'],
        },
        items: [orderItemSchema],
        status: {
            type: String,
            enum: ['New', 'In Progress', 'Ready', 'Urgent', 'Completed', 'Cancelled'],
            default: 'New',
        },
        totalAmount: {
            type: Number,
            required: [true, 'Please add a total amount'],
        },
        dueDate: {
            type: Date,
            required: [true, 'Please add a due date'],
        },
        priority: {
            type: String,
            enum: ['Low', 'Medium', 'High'],
            default: 'Medium',
        },
        notes: {
            type: String,
        },
        photos: [String],
        // Reference to the invoice, if generated
        invoice: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Invoice',
        },
        // Reference to the user who created the order
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Please add a user'],
        },
        // Reference to the user who last updated the order
        updatedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
    },
    {
        timestamps: true,
    }
);

// Generate order number before saving
orderSchema.pre('save', async function (next) {
    if (this.isNew) {
        const date = new Date();
        const year = date.getFullYear().toString().slice(-2);
        const month = (date.getMonth() + 1).toString().padStart(2, '0');

        // Find the latest order to increment the sequence
        const latestOrder = await this.constructor.findOne({}, {}, { sort: { 'createdAt': -1 } });

        let sequence = 1;
        if (latestOrder && latestOrder.orderNumber) {
            // Extract the sequence number from the last 4 digits of the existing order number
            const lastSequence = parseInt(latestOrder.orderNumber.slice(-4));
            if (!isNaN(lastSequence)) {
                sequence = lastSequence + 1;
            }
        }

        // Format: ORD-YYMM-SEQUENCE
        this.orderNumber = `ORD-${year}${month}-${sequence.toString().padStart(4, '0')}`;
    }

    next();
});

// Calculate total amount before saving
orderSchema.pre('save', function (next) {
    if (this.items && this.items.length > 0) {
        this.totalAmount = this.items.reduce(
            (total, item) => total + (item.price * item.quantity),
            0
        );
    }
    next();
});

module.exports = mongoose.model('Order', orderSchema); 