/**
 * Error handling middleware
 */
const errorHandler = (err, req, res, next) => {
    // Get status code
    const statusCode = res.statusCode ? res.statusCode : 500;

    // Log error for debugging in development
    if (process.env.NODE_ENV === 'development') {
        console.error(`Error: ${err.message}`.red);
        console.error(err.stack);
    }

    res.status(statusCode).json({
        success: false,
        error: err.message || 'Server Error',
        stack: process.env.NODE_ENV === 'production' ? null : err.stack,
    });
};

module.exports = {
    errorHandler,
}; 