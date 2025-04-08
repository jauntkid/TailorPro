import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ApiService {
  // Base URLs for different environments
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api'; // Web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5001/api'; // Android emulator
    } else if (Platform.isIOS) {
      // For iOS simulator use localhost, for real device use the actual IP
      return 'http://localhost:5001/api'; // iOS simulator
      // If testing on a real iOS device, comment the line above and uncomment this line:
      // return 'http://YOUR_ACTUAL_IP:5001/api'; // Replace with your machine's IP
    } else {
      return 'http://localhost:5001/api'; // Fallback
    }
  }

  // Headers
  Future<Map<String, String>> _getHeaders(
      {bool requireAuth = true, BuildContext? context}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('Getting headers - Current token: $token');

      if (token == null) {
        print('No token found in SharedPreferences');
        if (context != null) {
          // Clear any existing token
          await prefs.remove('token');
          // Navigate to login page
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        throw Exception('No token found');
      }

      headers['Authorization'] = 'Bearer $token';
      print('Headers with token: $headers');
    }

    return headers;
  }

  // Handle unauthorized response
  Future<void> _handleUnauthorized(BuildContext? context) async {
    // Clear token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Navigate to login if context is provided
    if (context != null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Generic API request handler
  Future<Map<String, dynamic>> _handleResponse(http.Response response,
      {BuildContext? context}) async {
    try {
      final data = jsonDecode(response.body);

      // Handle unauthorized response
      if (response.statusCode == 401) {
        await _handleUnauthorized(context);
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'unauthorized': true
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // If the response is already in the correct format, return it
        if (data is Map<String, dynamic> && data.containsKey('success')) {
          return data;
        }

        // Otherwise wrap the data in the expected format
        return {'success': true, 'data': data};
      } else {
        print('API Error: ${response.statusCode}, Body: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ??
              'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Response parsing error: $e, Body: ${response.body}');
      return {
        'success': false,
        'error': 'Failed to process response: ${response.body}'
      };
    }
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, dynamic>? queryParams,
      bool requireAuth = true,
      BuildContext? context}) async {
    try {
      final uri =
          Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      print('GET request to: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: requireAuth, context: context),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        if (context != null) {
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return {'success': false, 'unauthorized': true};
      }

      final data = jsonDecode(response.body);
      print('Parsed response: $data');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch data',
        };
      }
    } catch (e) {
      print('Error in GET request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body,
      bool requireAuth = true,
      BuildContext? context}) async {
    try {
      print('POST request to: $baseUrl$endpoint');
      if (body != null) {
        print('Request body: $body');
      }

      final headers =
          await _getHeaders(requireAuth: requireAuth, context: context);
      print('Request headers: $headers');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Parsed response: $data');

      if (response.statusCode == 401) {
        if (context != null) {
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return {'success': false, 'unauthorized': true};
      }

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': data,
        'error': data['message'] ?? 'Failed to create data',
      };
    } catch (e) {
      print('Error in POST request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body,
      bool requireAuth = true,
      BuildContext? context}) async {
    try {
      print('PUT request to: $baseUrl$endpoint');
      if (body != null) {
        print('Request body: $body');
      }

      final headers =
          await _getHeaders(requireAuth: requireAuth, context: context);
      print('Request headers: $headers');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Parsed response: $data');

      if (response.statusCode == 401) {
        if (context != null) {
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return {'success': false, 'unauthorized': true};
      }

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': data,
        'error': data['message'] ?? 'Failed to update data',
      };
    } catch (e) {
      print('Error in PUT request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint,
      {bool requireAuth = true, BuildContext? context}) async {
    try {
      print('DELETE request to: $baseUrl$endpoint');

      final headers =
          await _getHeaders(requireAuth: requireAuth, context: context);
      print('Request headers: $headers');

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Parsed response: $data');

      if (response.statusCode == 401) {
        if (context != null) {
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return {'success': false, 'unauthorized': true};
      }

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': data,
        'error': data['message'] ?? 'Failed to delete data',
      };
    } catch (e) {
      print('Error in DELETE request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData,
      {BuildContext? context}) async {
    final result = await post('/users/register',
        body: userData, requireAuth: false, context: context);
    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['data']['accessToken']);
    }
    return result;
  }

  Future<Map<String, dynamic>> login(String email, String password,
      {BuildContext? context}) async {
    try {
      print('Attempting login with email: $email');
      final response = await post('/users/login',
          body: {'email': email, 'password': password},
          requireAuth: false,
          context: context);

      print('Login response: $response');

      // Check if the response indicates successful authentication
      if (response['success'] &&
          response['data'] != null &&
          response['data']['accessToken'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(response['data']));
        print('User data stored in SharedPreferences');

        await prefs.setString('token', response['data']['accessToken']);
        print(
            'Token stored in SharedPreferences: ${response['data']['accessToken']}');

        return response;
      } else {
        // If no token is present, treat as failed login
        print('Login failed: No token in response');
        return {
          'success': false,
          'error': response['error'] ?? 'Invalid credentials'
        };
      }
    } catch (e) {
      print('Error in login: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser({BuildContext? context}) async {
    try {
      final response = await get('/users/profile', context: context);
      print('Current user response: $response');

      if (response['success'] == true && response['data'] != null) {
        // Handle nested data structure
        var userData = response['data'];
        if (userData is Map && userData.containsKey('data')) {
          userData = userData['data'];
        }

        return {'success': true, 'data': userData};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to fetch user profile'
      };
    } catch (e) {
      print('Error fetching current user: $e');
      return {'success': false, 'error': 'Error fetching user profile: $e'};
    }
  }

  Future<Map<String, dynamic>> logout({BuildContext? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response, context: context);
    } catch (e) {
      print('Logout error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Customer APIs
  Future<Map<String, dynamic>> getCustomers(
      {String? search, int? page, int? limit, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };
      return await get('/customers',
          queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching customers: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomer(String id,
      {BuildContext? context}) async {
    try {
      return await get('/customers/$id', context: context);
    } catch (e) {
      print('Error fetching customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomerOrders(String customerId) async {
    try {
      final response = await get('/customers/$customerId/orders');
      return response;
    } catch (e) {
      print('Error fetching customer orders: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData,
      {BuildContext? context}) async {
    try {
      return await post('/customers', body: customerData, context: context);
    } catch (e) {
      print('Error creating customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCustomer(
      String id, Map<String, dynamic> customerData,
      {BuildContext? context}) async {
    try {
      return await put('/customers/$id', body: customerData, context: context);
    } catch (e) {
      print('Error updating customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteCustomer(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/customers/$id', context: context);
    } catch (e) {
      print('Error deleting customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomerMeasurements(String customerId,
      {BuildContext? context}) async {
    try {
      return await get('/customers/$customerId/measurements', context: context);
    } catch (e) {
      print('Error fetching customer measurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addCustomerMeasurement(
      String customerId, Map<String, dynamic> measurementData,
      {BuildContext? context}) async {
    try {
      return await post('/customers/$customerId/measurements',
          body: measurementData, context: context);
    } catch (e) {
      print('Error adding customer measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeCustomerMeasurement(
      String customerId, String measurementId,
      {BuildContext? context}) async {
    try {
      return await delete('/customers/$customerId/measurements/$measurementId',
          context: context);
    } catch (e) {
      print('Error removing customer measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Category APIs
  Future<Map<String, dynamic>> getCategories(
      {String? search, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return await get('/categories',
          queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching categories: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCategory(String id,
      {BuildContext? context}) async {
    try {
      return await get('/categories/$id', context: context);
    } catch (e) {
      print('Error fetching category: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCategoryProducts(String categoryId) async {
    return await get('/categories/$categoryId/products');
  }

  // Product APIs
  Future<Map<String, dynamic>> getProducts(
      {String? search, String? category, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      };
      return await get('/products', queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching products: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProduct(String id,
      {BuildContext? context}) async {
    try {
      return await get('/products/$id', context: context);
    } catch (e) {
      print('Error fetching product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData,
      {BuildContext? context}) async {
    try {
      return await post('/products', body: productData, context: context);
    } catch (e) {
      print('Error creating product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> productData,
      {BuildContext? context}) async {
    try {
      return await put('/products/$id', body: productData, context: context);
    } catch (e) {
      print('Error updating product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/products/$id', context: context);
    } catch (e) {
      print('Error deleting product: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Measurement APIs
  Future<Map<String, dynamic>> getMeasurements(
      {String? search, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return await get('/measurements',
          queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching measurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMeasurement(String id,
      {BuildContext? context}) async {
    try {
      return await get('/measurements/$id', context: context);
    } catch (e) {
      print('Error fetching measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createMeasurement(
      Map<String, dynamic> measurementData,
      {BuildContext? context}) async {
    try {
      return await post('/measurements',
          body: measurementData, context: context);
    } catch (e) {
      print('Error creating measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMeasurement(
      String id, Map<String, dynamic> measurementData,
      {BuildContext? context}) async {
    try {
      return await put('/measurements/$id',
          body: measurementData, context: context);
    } catch (e) {
      print('Error updating measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMeasurement(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/measurements/$id', context: context);
    } catch (e) {
      print('Error deleting measurement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Order APIs
  Future<Map<String, dynamic>> getOrders(
      {String? search, int? page, int? limit, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };
      return await get('/orders', queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching orders: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrderById(String orderId,
      {BuildContext? context}) async {
    print('=== Starting getOrderById ===');
    print('Order ID: $orderId');

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/orders/$orderId');

      print('Making GET request to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        print('Unauthorized response received');
        if (context != null) {
          _handleUnauthorized(context);
        }
        return {'success': false, 'unauthorized': true};
      }

      final data = jsonDecode(response.body);
      print('Parsed response data: $data');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Success response received');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        print('Error response received');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch order details',
        };
      }
    } catch (e) {
      print('=== Error in getOrderById ===');
      print('Error details: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData,
      {BuildContext? context}) async {
    try {
      return await post('/orders', body: orderData, context: context);
    } catch (e) {
      print('Error creating order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrder(
      String id, Map<String, dynamic> orderData,
      {BuildContext? context}) async {
    try {
      return await put('/orders/$id', body: orderData, context: context);
    } catch (e) {
      print('Error updating order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteOrder(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/orders/$id', context: context);
    } catch (e) {
      print('Error deleting order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String itemId, String status,
      {BuildContext? context}) async {
    try {
      final response = await put('/orders/$orderId/status',
          body: {'orderId': orderId, 'itemId': itemId, 'newStatus': status},
          context: context);

      // Ensure success is always a boolean
      return {
        'success': response['success'] == true,
        'data': response['data'],
        'error': response['error'],
        'unauthorized': response['unauthorized'] == true
      };
    } catch (e) {
      print('Error updating order status: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomerById(String id,
      {BuildContext? context}) async {
    try {
      return await get('/customers/$id', context: context);
    } catch (e) {
      print('Error fetching customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessById(String id,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$id', context: context);
    } catch (e) {
      print('Error fetching business: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTestOrder({BuildContext? context}) async {
    try {
      // Create a test order with sample data
      final orderData = {
        'customer': null, // Will be filled by the backend with a test customer
        'items': [
          {
            'product':
                null, // Will be filled by the backend with a test product
            'quantity': 1,
            'price': 1000,
            'notes': 'Test order item'
          }
        ],
        'status': 'New',
        'priority': 'Medium',
        'notes': 'Test order created from app',
        'dueDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      };

      return await post('/orders/test', body: orderData, context: context);
    } catch (e) {
      print('Error creating test order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Invoice APIs
  Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int limit = 10,
    String? search,
    String? customer,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    return await get(
      '/invoices',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
        if (customer != null) 'customer': customer,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    return await get('/invoices/$id');
  }

  Future<Map<String, dynamic>> createInvoice(
      Map<String, dynamic> invoiceData) async {
    return await post('/invoices', body: invoiceData);
  }

  Future<Map<String, dynamic>> updateInvoice(
      String id, Map<String, dynamic> invoiceData) async {
    return await put('/invoices/$id', body: invoiceData);
  }

  Future<Map<String, dynamic>> addPayment(
      String invoiceId, Map<String, dynamic> paymentData) async {
    return await post('/invoices/$invoiceId/payments', body: paymentData);
  }

  // Generic API request handler with authentication
  Future<Map<String, dynamic>> _getWithAuth(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    return await get(endpoint, queryParams: queryParams, requireAuth: true);
  }

  // Get order with detailed item information
  Future<Map<String, dynamic>> getDetailedOrderItems(String orderId) async {
    try {
      print('Fetching detailed order items for ID: $orderId');

      // First get the basic order to ensure it exists
      final orderResponse = await get('/orders/$orderId');

      if (!orderResponse['success'] || orderResponse['data'] == null) {
        return orderResponse; // Return error if order doesn't exist
      }

      // Handle nested data structure (data: {success: true, data: {...}})
      var orderData = orderResponse['data'];

      // Check if data is nested within data
      if (orderData is Map &&
          orderData.containsKey('success') &&
          orderData.containsKey('data') &&
          orderData['data'] != null) {
        print(
            'Found nested data structure in detailed order, extracting inner data');
        // Extract the inner data object
        orderData = orderData['data'];
      }

      // If there are no items, return the original response
      if (!orderData.containsKey('items') ||
          orderData['items'] == null ||
          !(orderData['items'] is List) ||
          (orderData['items'] as List).isEmpty) {
        print('No items found in detailed order data');
        return {'success': true, 'data': orderData};
      }

      // Process each item to ensure complete product information
      List<dynamic> items = orderData['items'] as List;
      List<dynamic> enhancedItems = [];

      for (int i = 0; i < items.length; i++) {
        var item = items[i];

        // If product is just an ID, fetch the full product details
        if (item['product'] != null && item['product'] is String) {
          String productId = item['product'];
          print('Fetching details for product ID: $productId');

          try {
            final productResponse = await getProduct(productId);
            if (productResponse['success'] && productResponse['data'] != null) {
              // Handle nested product data
              var productData = productResponse['data'];
              if (productData is Map &&
                  productData.containsKey('success') &&
                  productData.containsKey('data') &&
                  productData['data'] != null) {
                productData = productData['data'];
              }

              // Replace the product ID with the full product object
              Map<String, dynamic> enhancedItem =
                  Map<String, dynamic>.from(item);
              enhancedItem['product'] = productData;
              print(
                  'Enhanced item with product details: ${productData['name'] ?? "Unknown"}');
              enhancedItems.add(enhancedItem);
            } else {
              // If product fetch fails, keep original data but add a name
              Map<String, dynamic> enhancedItem =
                  Map<String, dynamic>.from(item);

              // Try to fetch category info if available
              String categoryName = 'Unknown Category';
              if (item.containsKey('category') && item['category'] is String) {
                try {
                  final categoryResponse = await getCategory(item['category']);
                  if (categoryResponse['success'] &&
                      categoryResponse['data'] != null) {
                    var categoryData = categoryResponse['data'];
                    if (categoryData is Map &&
                        categoryData.containsKey('success') &&
                        categoryData.containsKey('data')) {
                      categoryData = categoryData['data'];
                    }
                    categoryName = categoryData['name'] ?? categoryName;
                  }
                } catch (e) {
                  print('Error fetching category: $e');
                }
              }

              if (!enhancedItem.containsKey('name')) {
                enhancedItem['name'] = '$categoryName Item #$productId';
              }
              if (!enhancedItem.containsKey('productName')) {
                enhancedItem['productName'] = '$categoryName Item #$productId';
              }
              print('Could not fetch product details, using placeholder name');
              enhancedItems.add(enhancedItem);
            }
          } catch (e) {
            print('Error fetching product details: $e');
            enhancedItems.add(item); // Keep original item on error
          }
        } else {
          // Keep items that already have product objects
          enhancedItems.add(item);
        }
      }

      // Replace the original items with enhanced items
      orderData['items'] = enhancedItems;

      return {
        'success': true,
        'data': orderData,
      };
    } catch (e) {
      print('Error fetching detailed order items: $e');
      return {
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getBusinesses(
      {String? search, BuildContext? context}) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return await get('/businesses',
          queryParams: queryParams, context: context);
    } catch (e) {
      print('Error fetching businesses: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusiness(String id,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$id', context: context);
    } catch (e) {
      print('Error fetching business: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createBusiness(Map<String, dynamic> businessData,
      {BuildContext? context}) async {
    try {
      return await post('/businesses', body: businessData, context: context);
    } catch (e) {
      print('Error creating business: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBusiness(
      String id, Map<String, dynamic> businessData,
      {BuildContext? context}) async {
    try {
      return await put('/businesses/$id', body: businessData, context: context);
    } catch (e) {
      print('Error updating business: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteBusiness(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/businesses/$id', context: context);
    } catch (e) {
      print('Error deleting business: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessOrders(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/orders', context: context);
    } catch (e) {
      print('Error fetching business orders: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessProducts(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/products', context: context);
    } catch (e) {
      print('Error fetching business products: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessCategories(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/categories', context: context);
    } catch (e) {
      print('Error fetching business categories: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessMeasurements(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/measurements',
          context: context);
    } catch (e) {
      print('Error fetching business measurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessReports(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/reports', context: context);
    } catch (e) {
      print('Error fetching business reports: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessAnalytics(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/analytics', context: context);
    } catch (e) {
      print('Error fetching business analytics: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessDashboard(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/dashboard', context: context);
    } catch (e) {
      print('Error fetching business dashboard: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessNotifications(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/notifications',
          context: context);
    } catch (e) {
      print('Error fetching business notifications: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessActivities(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/activities', context: context);
    } catch (e) {
      print('Error fetching business activities: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessUsers(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/users', context: context);
    } catch (e) {
      print('Error fetching business users: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addBusinessUser(String businessId, String userId,
      {BuildContext? context}) async {
    try {
      return await post('/businesses/$businessId/users',
          body: {'userId': userId}, context: context);
    } catch (e) {
      print('Error adding business user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeBusinessUser(
      String businessId, String userId,
      {BuildContext? context}) async {
    try {
      return await delete('/businesses/$businessId/users/$userId',
          context: context);
    } catch (e) {
      print('Error removing business user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessCustomers(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/customers', context: context);
    } catch (e) {
      print('Error fetching business customers: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addBusinessCustomer(
      String businessId, String customerId,
      {BuildContext? context}) async {
    try {
      return await post('/businesses/$businessId/customers',
          body: {'customerId': customerId}, context: context);
    } catch (e) {
      print('Error adding business customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeBusinessCustomer(
      String businessId, String customerId,
      {BuildContext? context}) async {
    try {
      return await delete('/businesses/$businessId/customers/$customerId',
          context: context);
    } catch (e) {
      print('Error removing business customer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBusinessSettings(String businessId,
      {BuildContext? context}) async {
    try {
      return await get('/businesses/$businessId/settings', context: context);
    } catch (e) {
      print('Error fetching business settings: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBusinessSettings(
      String businessId, Map<String, dynamic> settingsData,
      {BuildContext? context}) async {
    try {
      return await put('/businesses/$businessId/settings',
          body: settingsData, context: context);
    } catch (e) {
      print('Error updating business settings: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData,
      {BuildContext? context}) async {
    try {
      return await post('/categories', body: categoryData, context: context);
    } catch (e) {
      print('Error creating category: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> categoryData,
      {BuildContext? context}) async {
    try {
      return await put('/categories/$id', body: categoryData, context: context);
    } catch (e) {
      print('Error updating category: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteCategory(String id,
      {BuildContext? context}) async {
    try {
      return await delete('/categories/$id', context: context);
    } catch (e) {
      print('Error deleting category: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
