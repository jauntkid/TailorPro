# SiriAPI - Tailor Shop Management System

A RESTful API for managing a tailor shop business, built with Node.js, Express, and MongoDB.

## Features

- **User Management**: Registration, authentication, and authorization with JWT
- **Customer Management**: Store and manage customer information and measurements
- **Product & Category Management**: Manage product catalog with categories
- **Measurement Management**: Store customer measurements by category
- **Order Management**: Create and track orders with status updates
- **Invoice & Payment Management**: Generate invoices and record payments

## Tech Stack

- **Node.js & Express**: Server and API framework
- **MongoDB & Mongoose**: Database and ODM
- **JWT**: Authentication and authorization
- **BCrypt**: Password hashing

## Getting Started

### Prerequisites

- Node.js (v14 or later)
- MongoDB (local or Atlas)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/siriapi.git
   cd siriapi
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Create a `.env` file in the root directory with the following variables:
   ```
   NODE_ENV=development
   PORT=5000
   MONGO_URI=mongodb://localhost:27017/siriapi
   JWT_SECRET=your_jwt_secret
   JWT_EXPIRES_IN=1d
   REFRESH_TOKEN_SECRET=your_refresh_token_secret
   REFRESH_TOKEN_EXPIRES_IN=30d
   CLIENT_URL=http://localhost:3000
   ```

4. Start the development server:
   ```
   npm run dev
   ```

## API Documentation

### Base URL

```
http://localhost:5000/api
```

### Authentication Endpoints

- `POST /users/register` - Register a new user
- `POST /users/login` - Login and get access token
- `POST /users/refresh-token` - Refresh access token
- `POST /users/logout` - Logout (requires auth)

### Customer Endpoints

- `GET /customers` - Get all customers (requires auth)
- `GET /customers/:id` - Get a specific customer (requires auth)
- `POST /customers` - Create a new customer (requires auth)
- `PUT /customers/:id` - Update a customer (requires auth)
- `DELETE /customers/:id` - Delete a customer (requires auth)
- `GET /customers/:id/orders` - Get customer orders (requires auth)
- `GET /customers/:id/measurements` - Get customer measurements (requires auth)

### Category Endpoints

- `GET /categories` - Get all categories (requires auth)
- `GET /categories/:id` - Get a specific category (requires auth)
- `POST /categories` - Create a new category (requires admin)
- `PUT /categories/:id` - Update a category (requires admin)
- `DELETE /categories/:id` - Delete a category (requires admin)
- `GET /categories/:id/products` - Get category products (requires auth)

### Product Endpoints

- `GET /products` - Get all products (requires auth)
- `GET /products/:id` - Get a specific product (requires auth)
- `POST /products` - Create a new product (requires admin)
- `PUT /products/:id` - Update a product (requires admin)
- `DELETE /products/:id` - Delete a product (requires admin)

### Measurement Endpoints

- `GET /measurements` - Get all measurements (requires auth)
- `GET /measurements/:id` - Get a specific measurement (requires auth)
- `POST /measurements` - Create a new measurement (requires auth)
- `PUT /measurements/:id` - Update a measurement (requires auth)
- `DELETE /measurements/:id` - Delete a measurement (requires auth)

### Order Endpoints

- `GET /orders` - Get all orders (requires auth)
- `GET /orders/:id` - Get a specific order (requires auth)
- `POST /orders` - Create a new order (requires auth)
- `PUT /orders/:id` - Update an order (requires auth)
- `PUT /orders/:id/status` - Update order status (requires auth)
- `DELETE /orders/:id` - Delete an order (requires admin)

### Invoice Endpoints

- `GET /invoices` - Get all invoices (requires auth)
- `GET /invoices/:id` - Get a specific invoice (requires auth)
- `POST /invoices` - Create a new invoice (requires auth)
- `PUT /invoices/:id` - Update an invoice (requires auth)
- `DELETE /invoices/:id` - Delete an invoice (requires admin)
- `POST /invoices/:id/payments` - Add payment to invoice (requires auth)
- `DELETE /invoices/:id/payments/:paymentId` - Remove payment (requires admin)

## License

This project is licensed under the ISC License. 