Required APIs for the Tailoring Shop App
1. Authentication & User Management APIs
POST /api/auth/login - User login
POST /api/auth/register - Register new tailor shop staff
POST /api/auth/logout - User logout
GET /api/auth/me - Get current user profile
PUT /api/auth/me - Update user profile
POST /api/auth/refresh-token - Refresh authentication token
2. Customer Management APIs
GET /api/customers - List customers (with pagination, filtering, search)
POST /api/customers - Create new customer
GET /api/customers/{id} - Get customer details
PUT /api/customers/{id} - Update customer information
DELETE /api/customers/{id} - Delete customer
GET /api/customers/{id}/orders - Get orders by customer
3. Order Management APIs
GET /api/orders - List orders (with filters for status, date range)
POST /api/orders - Create new order
GET /api/orders/{id} - Get order details
PUT /api/orders/{id} - Update order details
PUT /api/orders/{id}/status - Update order status (In Progress, Ready, etc.)
DELETE /api/orders/{id} - Delete order
GET /api/orders/stats - Get order statistics and summaries
4. Measurement APIs
GET /api/measurements/templates - Get measurement templates by category
GET /api/customers/{id}/measurements - Get customer measurements
POST /api/customers/{id}/measurements - Save customer measurements
PUT /api/customers/{id}/measurements/{id} - Update specific measurement set
5. Product/Category APIs
GET /api/categories - Get all product categories
POST /api/categories - Create product category
PUT /api/categories/{id} - Update category
GET /api/categories/{id}/measurements - Get measurements for category
GET /api/products - Get all products/items with default pricing
POST /api/products - Create new product/item
PUT /api/products/{id} - Update product/item
6. Billing & Payment APIs
GET /api/invoices - List invoices
POST /api/invoices - Generate invoice for order
GET /api/invoices/{id} - Get invoice details
POST /api/invoices/{id}/send - Send invoice (email/WhatsApp)
POST /api/payments - Record payment for invoice
GET /api/payments - List payments received
7. Settings & Configuration APIs
GET /api/settings - Get app settings
PUT /api/settings - Update app settings
GET /api/settings/pricing - Get default pricing
PUT /api/settings/pricing - Update default pricing
GET /api/settings/business - Get business info
PUT /api/settings/business - Update business info
8. Analytics APIs
GET /api/analytics/revenue - Get revenue data
GET /api/analytics/orders - Get order analytics
GET /api/analytics/customers - Get customer analytics
9. Notification APIs
GET /api/notifications - Get user notifications
PUT /api/notifications/{id} - Mark notification as read
POST /api/notifications/settings - Update notification preferences