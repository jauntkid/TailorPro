const swaggerJsDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

// Swagger options
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Siri Tailor Shop API',
            version: '1.0.0',
            description: 'API documentation for Siri Tailor Shop Management System',
            contact: {
                name: 'API Support',
                email: 'support@siritailor.com'
            },
            license: {
                name: 'ISC',
                url: 'https://opensource.org/licenses/ISC'
            }
        },
        servers: [
            {
                url: 'http://localhost:5001',
                description: 'Development server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        },
        security: [
            {
                bearerAuth: []
            }
        ]
    },
    apis: ['./src/routes/*.js', './src/models/*.js', './src/swagger/*.js']
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);

module.exports = {
    serve: swaggerUi.serve,
    setup: swaggerUi.setup(swaggerDocs, {
        explorer: true,
        customCss: '.swagger-ui .topbar { display: none }',
        customSiteTitle: 'Siri Tailor Shop API Documentation'
    })
}; 