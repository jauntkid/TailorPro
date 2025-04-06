/**
 * @swagger
 * tags:
 *   - name: Health
 *     description: API health check
 * 
 * /api/health:
 *   get:
 *     summary: Check API health status
 *     tags: [Health]
 *     security: []
 *     responses:
 *       200:
 *         description: API is up and running
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                   example: API is up and running
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   example: 2023-04-06T08:00:00.000Z
 */ 