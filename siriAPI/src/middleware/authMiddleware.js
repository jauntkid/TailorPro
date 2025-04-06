const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

/**
 * Protect routes middleware
 * Verifies JWT token and attaches user to request object
 */
const protect = async (req, res, next) => {
    try {
        let token;

        // Check for token in headers
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];
        }

        // Check if token exists
        if (!token) {
            return res.status(401).json({
                success: false,
                error: 'Not authorized, no token provided',
            });
        }

        try {
            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Get user from database and attach to request
            req.user = await User.findById(decoded.id).select('-password');

            // Check if user exists
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    error: 'Not authorized, user not found',
                });
            }

            next();
        } catch (error) {
            res.status(401).json({
                success: false,
                error: 'Not authorized, token failed',
            });
        }
    } catch (error) {
        next(error);
    }
};

/**
 * Admin middleware
 * Checks if the authenticated user is an admin
 */
const admin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({
            success: false,
            error: 'Not authorized as an admin',
        });
    }
};

module.exports = {
    protect,
    admin,
}; 