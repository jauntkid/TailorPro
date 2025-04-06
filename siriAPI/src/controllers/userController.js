const User = require('../models/userModel');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const jwt = require('jsonwebtoken');

/**
 * @desc    Register a new user
 * @route   POST /api/users/register
 * @access  Public
 */
const registerUser = asyncHandler(async (req, res) => {
    const { name, email, password, role, phone } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });

    if (userExists) {
        throw new ErrorResponse('User already exists', 400);
    }

    // Create user
    const user = await User.create({
        name,
        email,
        password,
        role,
        phone,
    });

    // Generate tokens
    const accessToken = user.getSignedJwtToken();
    const refreshToken = user.getRefreshToken();

    // Save refresh token to user
    user.refreshToken = refreshToken;
    await user.save();

    // Set cookie with refresh token
    res.cookie('refreshToken', refreshToken, {
        httpOnly: true,
        maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    });

    sendTokenResponse(user, 201, res);
});

/**
 * @desc    Login user
 * @route   POST /api/users/login
 * @access  Public
 */
const loginUser = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Check for user
    const user = await User.findOne({ email }).select('+password');
    console.log(user);
    if (!user) {
        throw new ErrorResponse('User Not found', 401);
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);
    console.log(isMatch, password, user.password);
    if (!isMatch) {
        throw new ErrorResponse('Invalid credentials', 401);
    }

    // Generate tokens
    const accessToken = user.getSignedJwtToken();
    const refreshToken = user.getRefreshToken();

    // Save refresh token to user
    user.refreshToken = refreshToken;
    await user.save();

    // Set cookie with refresh token
    res.cookie('refreshToken', refreshToken, {
        httpOnly: true,
        maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    });

    sendTokenResponse(user, 200, res);
});

/**
 * @desc    Logout user / clear cookie
 * @route   POST /api/users/logout
 * @access  Private
 */
const logoutUser = asyncHandler(async (req, res) => {
    // Clear refresh token in DB
    req.user.refreshToken = '';
    await req.user.save();

    // Clear cookie
    res.cookie('refreshToken', '', {
        httpOnly: true,
        expires: new Date(0),
    });

    res.status(200).json({
        success: true,
        message: 'Logged out successfully',
    });
});

/**
 * @desc    Get user profile
 * @route   GET /api/users/profile
 * @access  Private
 */
const getUserProfile = asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id);

    res.status(200).json({
        success: true,
        data: user,
    });
});

/**
 * @desc    Update user profile
 * @route   PUT /api/users/profile
 * @access  Private
 */
const updateUserProfile = asyncHandler(async (req, res) => {
    const { name, email, phone, profileImage } = req.body;

    const user = await User.findById(req.user.id);

    if (user) {
        user.name = name || user.name;
        user.email = email || user.email;
        user.phone = phone || user.phone;
        user.profileImage = profileImage || user.profileImage;

        const updatedUser = await user.save();

        res.status(200).json({
            success: true,
            data: updatedUser,
        });
    } else {
        throw new ErrorResponse('User not found', 404);
    }
});

/**
 * @desc    Update user password
 * @route   PUT /api/users/password
 * @access  Private
 */
const updatePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    const isMatch = await user.matchPassword(currentPassword);

    if (!isMatch) {
        throw new ErrorResponse('Current password is incorrect', 401);
    }

    // Set new password
    user.password = newPassword;
    await user.save();

    res.status(200).json({
        success: true,
        message: 'Password updated successfully',
    });
});

/**
 * @desc    Refresh access token
 * @route   POST /api/users/refresh-token
 * @access  Public
 */
const refreshToken = asyncHandler(async (req, res) => {
    // Get refresh token from cookie
    const refreshToken = req.cookies.refreshToken;

    if (!refreshToken) {
        throw new ErrorResponse('No refresh token found', 401);
    }

    try {
        // Verify token
        const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);

        // Check if user exists
        const user = await User.findById(decoded.id);

        if (!user) {
            throw new ErrorResponse('User not found', 404);
        }

        // Check if refresh token matches
        if (refreshToken !== user.refreshToken) {
            throw new ErrorResponse('Invalid refresh token', 401);
        }

        // Generate new access token
        const accessToken = user.getSignedJwtToken();

        res.status(200).json({
            success: true,
            accessToken,
        });
    } catch (error) {
        throw new ErrorResponse('Invalid token', 401);
    }
});

/**
 * @desc    Get all users (admin only)
 * @route   GET /api/users
 * @access  Private/Admin
 */
const getUsers = asyncHandler(async (req, res) => {
    const users = await User.find({});

    res.status(200).json({
        success: true,
        count: users.length,
        data: users,
    });
});

/**
 * @desc    Get user by ID (admin only)
 * @route   GET /api/users/:id
 * @access  Private/Admin
 */
const getUserById = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        throw new ErrorResponse(`User not found with id of ${req.params.id}`, 404);
    }

    res.status(200).json({
        success: true,
        data: user,
    });
});

/**
 * @desc    Update user (admin only)
 * @route   PUT /api/users/:id
 * @access  Private/Admin
 */
const updateUser = asyncHandler(async (req, res) => {
    const { name, email, role, phone, profileImage, isActive } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
        throw new ErrorResponse(`User not found with id of ${req.params.id}`, 404);
    }

    user.name = name || user.name;
    user.email = email || user.email;
    user.role = role || user.role;
    user.phone = phone || user.phone;
    user.profileImage = profileImage || user.profileImage;

    const updatedUser = await user.save();

    res.status(200).json({
        success: true,
        data: updatedUser,
    });
});

/**
 * @desc    Delete user (admin only)
 * @route   DELETE /api/users/:id
 * @access  Private/Admin
 */
const deleteUser = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        throw new ErrorResponse(`User not found with id of ${req.params.id}`, 404);
    }

    await user.remove();

    res.status(200).json({
        success: true,
        data: {},
    });
});

// Helper function to send token response
const sendTokenResponse = (user, statusCode, res) => {
    // Create token
    const accessToken = user.getSignedJwtToken();

    // Remove sensitive fields from response
    const userData = {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        profileImage: user.profileImage,
    };

    res.status(statusCode).json({
        success: true,
        accessToken,
        data: userData,
    });
};

module.exports = {
    registerUser,
    loginUser,
    logoutUser,
    getUserProfile,
    updateUserProfile,
    updatePassword,
    refreshToken,
    getUsers,
    getUserById,
    updateUser,
    deleteUser,
}; 