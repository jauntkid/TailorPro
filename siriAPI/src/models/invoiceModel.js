const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    amount: {
        type: Number,
        required: [true, 'Please add a payment amount'],
    },
    method: {
        type: String,
        enum: ['Cash', 'Card', 'Mobile Money', 'Bank Transfer', 'Other'],
        required: [true, 'Please add a payment method'],
    },
    date: {
        type: Date,
        default: Date.now,
    },
    transactionId: {
        type: String,
    },
    notes: {
        type: String,
    },
    // Reference to the user who recorded the payment
    recordedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
});

const invoiceSchema = new mongoose.Schema(
    {
        invoiceNumber: {
            type: String,
            required: true,
            unique: true,
        },
        customer: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Customer',
            required: [true, 'Please add a customer'],
        },
        order: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order',
            required: [true, 'Please add an order'],
        },
        issueDate: {
            type: Date,
            default: Date.now,
        },
        dueDate: {
            type: Date,
            required: [true, 'Please add a due date'],
        },
        subtotal: {
            type: Number,
            required: [true, 'Please add a subtotal'],
        },
        discount: {
            type: Number,
            default: 0,
        },
        tax: {
            type: Number,
            default: 0,
        },
        totalAmount: {
            type: Number,
            required: [true, 'Please add a total amount'],
        },
        amountPaid: {
            type: Number,
            default: 0,
        },
        balance: {
            type: Number,
        },
        status: {
            type: String,
            enum: ['Unpaid', 'Partially Paid', 'Paid', 'Cancelled'],
            default: 'Unpaid',
        },
        payments: [paymentSchema],
        notes: {
            type: String,
        },
        // Reference to the user who created the invoice
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Please add a user'],
        },
    },
    {
        timestamps: true,
    }
);

// Generate invoice number before saving
invoiceSchema.pre('save', async function (next) {
    if (this.isNew) {
        const date = new Date();
        const year = date.getFullYear().toString().slice(-2);
        const month = (date.getMonth() + 1).toString().padStart(2, '0');

        // Find the latest invoice to increment the sequence
        const latestInvoice = await this.constructor.findOne({}, {}, { sort: { 'createdAt': -1 } });

        let sequence = 1;
        if (latestInvoice && latestInvoice.invoiceNumber) {
            // Extract the sequence number from the last 4 digits of the existing invoice number
            const lastSequence = parseInt(latestInvoice.invoiceNumber.slice(-4));
            if (!isNaN(lastSequence)) {
                sequence = lastSequence + 1;
            }
        }

        // Format: INV-YYMM-SEQUENCE
        this.invoiceNumber = `INV-${year}${month}-${sequence.toString().padStart(4, '0')}`;
    }

    next();
});

// Calculate balance before saving
invoiceSchema.pre('save', function (next) {
    // Calculate total amount if not provided
    if (!this.totalAmount && this.subtotal) {
        this.totalAmount = this.subtotal + this.tax - this.discount;
    }

    // Calculate amount paid from payments
    if (this.payments && this.payments.length > 0) {
        this.amountPaid = this.payments.reduce((total, payment) => total + payment.amount, 0);
    }

    // Calculate balance
    this.balance = this.totalAmount - this.amountPaid;

    // Update status based on payment
    if (this.balance <= 0) {
        this.status = 'Paid';
    } else if (this.amountPaid > 0) {
        this.status = 'Partially Paid';
    } else {
        this.status = 'Unpaid';
    }

    next();
});

module.exports = mongoose.model('Invoice', invoiceSchema); 