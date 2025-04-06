const mongoose = require('mongoose');
const colors = require('colors');
const dotenv = require('dotenv');
const User = require('../models/userModel');
const Category = require('../models/categoryModel');
const Product = require('../models/productModel');

// Load env vars
dotenv.config();

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

// Create admin user
const createAdminUser = async () => {
    try {
        // Clear existing admin users
        await User.deleteMany({ role: 'admin' });

        // Create admin user
        await User.create({
            name: 'Admin User 2',
            email: 'nik@siri.com',
            password: 'password',
            role: 'admin',
            phone: '1234567890',
        });

        console.log('Admin user created!'.green.inverse);
    } catch (err) {
        console.error(`${err}`.red);
    }
};

// Create sample categories
const createCategories = async () => {
    try {
        // Clear existing categories
        await Category.deleteMany();

        // Create categories
        const categories = await Category.create([
            {
                title: 'Shirts',
                icon: 'shirt',
                gradientColors: ['#4A90E2', '#5A6BCC'],
                requiredMeasurements: ['Neck', 'Chest', 'Waist', 'Hips', 'Sleeve Length', 'Shoulder']
            },
            {
                title: 'Pants',
                icon: 'pants',
                gradientColors: ['#50C878', '#34A56F'],
                requiredMeasurements: ['Waist', 'Hips', 'Inseam', 'Outseam', 'Thigh', 'Knee', 'Cuff']
            },
            {
                title: 'Suits',
                icon: 'suit',
                gradientColors: ['#8A2BE2', '#6A5ACD'],
                requiredMeasurements: ['Chest', 'Waist', 'Hips', 'Shoulder', 'Sleeve Length', 'Jacket Length', 'Inseam']
            }
        ]);

        console.log('Sample categories created!'.green.inverse);
        return categories;
    } catch (err) {
        console.error(`${err}`.red);
        return [];
    }
};

// Create sample products
const createProducts = async (categories) => {
    try {
        // Clear existing products
        await Product.deleteMany();

        if (!categories || categories.length === 0) {
            console.log('No categories found, skipping products'.yellow);
            return;
        }

        const shirtsCategory = categories.find(c => c.title === 'Shirts');
        const pantsCategory = categories.find(c => c.title === 'Pants');
        const suitsCategory = categories.find(c => c.title === 'Suits');

        // Create products
        const products = [
            // Shirts
            {
                name: 'Formal Shirt',
                description: 'Tailored formal shirt for business wear',
                price: 1200,
                category: shirtsCategory._id,
                image: 'formal-shirt.jpg',
                icon: 'shirt',
                isActive: true,
                measurements: [
                    { name: 'Neck', unit: 'in', minValue: 13, maxValue: 20 },
                    { name: 'Chest', unit: 'in', minValue: 34, maxValue: 50 },
                    { name: 'Waist', unit: 'in', minValue: 28, maxValue: 46 },
                    { name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28 },
                    { name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22 }
                ]
            },
            {
                name: 'Casual Shirt',
                description: 'Comfortable casual shirt for everyday wear',
                price: 800,
                category: shirtsCategory._id,
                image: 'casual-shirt.jpg',
                icon: 'shirt',
                isActive: true,
                measurements: [
                    { name: 'Neck', unit: 'in', minValue: 13, maxValue: 20 },
                    { name: 'Chest', unit: 'in', minValue: 34, maxValue: 50 },
                    { name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22 },
                    { name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28 }
                ]
            },
            // Pants
            {
                name: 'Formal Trousers',
                description: 'Tailored formal trousers for business wear',
                price: 1500,
                category: pantsCategory._id,
                image: 'formal-pants.jpg',
                icon: 'pants',
                isActive: true,
                measurements: [
                    { name: 'Waist', unit: 'in', minValue: 28, maxValue: 46 },
                    { name: 'Hips', unit: 'in', minValue: 34, maxValue: 52 },
                    { name: 'Inseam', unit: 'in', minValue: 26, maxValue: 36 },
                    { name: 'Outseam', unit: 'in', minValue: 36, maxValue: 46 },
                    { name: 'Thigh', unit: 'in', minValue: 18, maxValue: 32 },
                    { name: 'Knee', unit: 'in', minValue: 14, maxValue: 24 },
                    { name: 'Cuff', unit: 'in', minValue: 14, maxValue: 22 }
                ]
            },
            {
                name: 'Casual Pants',
                description: 'Comfortable casual pants for everyday wear',
                price: 1000,
                category: pantsCategory._id,
                image: 'casual-pants.jpg',
                icon: 'pants',
                isActive: true,
                measurements: [
                    { name: 'Waist', unit: 'in', minValue: 28, maxValue: 46 },
                    { name: 'Hips', unit: 'in', minValue: 34, maxValue: 52 },
                    { name: 'Inseam', unit: 'in', minValue: 26, maxValue: 36 },
                    { name: 'Thigh', unit: 'in', minValue: 18, maxValue: 32 }
                ]
            },
            // Suits
            {
                name: 'Business Suit',
                description: 'Full business suit with jacket and trousers',
                price: 5000,
                category: suitsCategory._id,
                image: 'business-suit.jpg',
                icon: 'suit',
                isActive: true,
                measurements: [
                    { name: 'Chest', unit: 'in', minValue: 34, maxValue: 50 },
                    { name: 'Waist', unit: 'in', minValue: 28, maxValue: 46 },
                    { name: 'Hips', unit: 'in', minValue: 34, maxValue: 52 },
                    { name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22 },
                    { name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28 },
                    { name: 'Jacket Length', unit: 'in', minValue: 26, maxValue: 36 },
                    { name: 'Inseam', unit: 'in', minValue: 26, maxValue: 36 }
                ]
            },
            {
                name: 'Wedding Suit',
                description: 'Elegant suit for special occasions',
                price: 8000,
                category: suitsCategory._id,
                image: 'wedding-suit.jpg',
                icon: 'suit',
                isActive: true,
                measurements: [
                    { name: 'Chest', unit: 'in', minValue: 34, maxValue: 50 },
                    { name: 'Waist', unit: 'in', minValue: 28, maxValue: 46 },
                    { name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22 },
                    { name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28 },
                    { name: 'Jacket Length', unit: 'in', minValue: 26, maxValue: 36 },
                    { name: 'Neck', unit: 'in', minValue: 13, maxValue: 20 },
                    { name: 'Inseam', unit: 'in', minValue: 26, maxValue: 36 }
                ]
            }
        ];

        await Product.create(products);
        console.log('Sample products created!'.green.inverse);
    } catch (err) {
        console.error(`${err}`.red);
    }
};

// Run seeder functions
const seedDatabase = async () => {
    try {
        await createAdminUser();
        const categories = await createCategories();
        await createProducts(categories);

        console.log('Database seeded successfully!'.green.bold);
        process.exit(0);
    } catch (err) {
        console.error(`${err}`.red);
        process.exit(1);
    }
};

seedDatabase();
