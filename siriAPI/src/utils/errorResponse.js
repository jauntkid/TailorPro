/**
 * Custom error response class
 * @extends Error
 */
class ErrorResponse extends Error {
    /**
     * Create a new ErrorResponse instance
     * @param {string} message - Error message
     * @param {number} statusCode - HTTP status code
     */
    constructor(message, statusCode) {
        super(message);
        this.statusCode = statusCode;
    }
}

module.exports = ErrorResponse; 