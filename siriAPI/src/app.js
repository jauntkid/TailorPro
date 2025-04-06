const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const morgan = require('morgan');
const colors = require('colors');
const routes = require('./routes');
const { errorHandler } = require('./middleware/errorMiddleware');
const swagger = require('./utils/swagger');

// Create Express app
const app = express();

// Middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
}

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Cookie parser
app.use(cookieParser());

// CORS
app.use(cors({
    origin: process.env.CLIENT_URL || 'http://localhost:3000',
    credentials: true,
}));

// Swagger UI
app.use('/api-docs', swagger.serve, swagger.setup);

// Root route
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Welcome to Siri Tailor Shop API',
        version: '1.0.0',
        endpoints: '/api',
        documentation: '/api-docs'
    });
});

// API routes
app.use('/api', routes);

// 404 handler
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        error: `Route ${req.originalUrl} not found`,
    });
});

// Error handler
app.use(errorHandler);

module.exports = app; 