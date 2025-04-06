/**
 * @swagger
 * tags:
 *   - name: Customers
 *     description: Customer management
 * 
 * components:
 *   schemas:
 *     Customer:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           description: The auto-generated MongoDB ID
 *         name:
 *           type: string
 *           description: Customer's full name
 *         phone:
 *           type: string
 *           description: Customer's phone number
 *         email:
 *           type: string
 *           description: Customer's email address
 *         address:
 *           type: string
 *           description: Customer's address
 *         referral:
 *           type: string
 *           description: Where the customer heard about the shop
 *         notes:
 *           type: string
 *           description: Additional notes about the customer
 *         profileImage:
 *           type: string
 *           description: URL to customer's profile image
 *         measurements:
 *           type: array
 *           items:
 *             type: string
 *           description: Array of measurement IDs
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       required:
 *         - name
 *         - phone
 *       example:
 *         name: John Smith
 *         phone: "1234567890"
 *         email: john@example.com
 *         address: "123 Main St, City, Country"
 *         referral: "Friend"
 *         notes: "Prefers slim fit"
 *         profileImage: "default-customer.jpg"
 *
 * /api/customers:
 *   get:
 *     summary: Get all customers
 *     tags: [Customers]
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search term for customer name, phone or email
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of customers per page
 *     responses:
 *       200:
 *         description: List of customers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 pagination:
 *                   type: object
 *                 total:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Customer'
 *
 *   post:
 *     summary: Create a new customer
 *     tags: [Customers]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - phone
 *             properties:
 *               name:
 *                 type: string
 *                 example: John Smith
 *               phone:
 *                 type: string
 *                 example: "1234567890"
 *               email:
 *                 type: string
 *                 example: john@example.com
 *               address:
 *                 type: string
 *                 example: "123 Main St, City, Country"
 *               referral:
 *                 type: string
 *                 example: "Friend"
 *               notes:
 *                 type: string
 *                 example: "Prefers slim fit"
 *               profileImage:
 *                 type: string
 *                 example: "default-customer.jpg"
 *     responses:
 *       201:
 *         description: Customer created successfully
 *       400:
 *         description: Customer with same phone already exists or invalid input
 *
 * /api/customers/{id}:
 *   get:
 *     summary: Get customer by ID
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *     responses:
 *       200:
 *         description: Customer details
 *       404:
 *         description: Customer not found
 *
 *   put:
 *     summary: Update customer
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Customer'
 *     responses:
 *       200:
 *         description: Customer updated successfully
 *       404:
 *         description: Customer not found
 *
 *   delete:
 *     summary: Delete customer
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *     responses:
 *       200:
 *         description: Customer deleted successfully
 *       404:
 *         description: Customer not found
 *
 * /api/customers/{id}/orders:
 *   get:
 *     summary: Get customer orders
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *     responses:
 *       200:
 *         description: List of customer orders
 *       404:
 *         description: Customer not found
 *
 * /api/customers/{id}/measurements:
 *   get:
 *     summary: Get customer measurements
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Customer ID
 *     responses:
 *       200:
 *         description: List of customer measurements
 *       404:
 *         description: Customer not found
 */ 