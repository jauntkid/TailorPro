import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic API request handler
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
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

  Future<Map<String, dynamic>> _get(String endpoint,
      {Map<String, dynamic>? queryParams, bool requireAuth = true}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(
            queryParameters: queryParams
                .map((key, value) => MapEntry(key, value?.toString())));
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: requireAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      print('GET error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint,
      {Map<String, dynamic>? body, bool requireAuth = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      print('POST error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _put(String endpoint,
      {Map<String, dynamic>? body, bool requireAuth = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      print('PUT error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint,
      {bool requireAuth = true}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requireAuth: requireAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DELETE error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final result =
        await _post('/users/register', body: userData, requireAuth: false);
    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['data']['accessToken']);
    }
    return result;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _post(
      '/users/login',
      body: {'email': email, 'password': password},
      requireAuth: false,
    );

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['data']['accessToken']);
    }
    return result;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _get('/users/me');
  }

  Future<Map<String, dynamic>> logout() async {
    final result = await _post('/users/logout');
    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
    return result;
  }

  // Customer APIs
  Future<Map<String, dynamic>> getCustomers(
      {int page = 1, int limit = 10, String? search}) async {
    try {
      String url = '$baseUrl/customers?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomerById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$id'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createCustomer(
      Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: await _getHeaders(),
        body: json.encode(customerData),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCustomer(
      String id, Map<String, dynamic> customerData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customers/$id'),
        headers: await _getHeaders(),
        body: json.encode(customerData),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteCustomer(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$id'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCustomerOrders(String customerId) async {
    return await _get('/customers/$customerId/orders');
  }

  Future<Map<String, dynamic>> getCustomerMeasurements(
      String customerId) async {
    return await _get('/customers/$customerId/measurements');
  }

  // Category APIs
  Future<Map<String, dynamic>> getCategories() async {
    return await _get('/categories');
  }

  Future<Map<String, dynamic>> getCategory(String id) async {
    return await _get('/categories/$id');
  }

  Future<Map<String, dynamic>> getCategoryProducts(String categoryId) async {
    return await _get('/categories/$categoryId/products');
  }

  // Product APIs
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    bool? active,
  }) async {
    return await _get(
      '/products',
      queryParams: {
        'page': page,
        'limit': limit,
        'search': search,
        'category': category,
        'active': active,
      },
    );
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    return await _get('/products/$id');
  }

  // Measurement APIs
  Future<Map<String, dynamic>> getMeasurements({
    int page = 1,
    int limit = 10,
    String? customer,
    String? category,
  }) async {
    return await _get(
      '/measurements',
      queryParams: {
        'page': page,
        'limit': limit,
        'customer': customer,
        'category': category,
      },
    );
  }

  Future<Map<String, dynamic>> getMeasurement(String id) async {
    return await _get('/measurements/$id');
  }

  Future<Map<String, dynamic>> createMeasurement(
      Map<String, dynamic> measurementData) async {
    return await _post('/measurements', body: measurementData);
  }

  Future<Map<String, dynamic>> updateMeasurement(
      String id, Map<String, dynamic> measurementData) async {
    return await _put('/measurements/$id', body: measurementData);
  }

  // Order APIs
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? search,
    String? customer,
    String? status,
    String? priority,
    String? startDate,
    String? endDate,
  }) async {
    return await _get(
      '/orders',
      queryParams: {
        'page': page,
        'limit': limit,
        'search': search,
        'customer': customer,
        'status': status,
        'priority': priority,
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      print('Fetching order details for ID: $orderId');

      // Handle any query parameters in the orderId
      String endpoint = '/orders/';
      if (orderId.contains('?')) {
        final parts = orderId.split('?');
        endpoint += parts[0];
        endpoint += '?' + parts[1];
      } else {
        endpoint += orderId;
        // Add a timestamp to prevent caching
        endpoint += '?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final response = await _get(endpoint);
      print('API response for order: $response');

      // Check if we have a successful response
      if (response['success'] == true && response['data'] != null) {
        // Handle nested data structure (data: {success: true, data: {...}})
        final data = response['data'];

        // Check if data is nested within data
        if (data is Map &&
            data.containsKey('success') &&
            data.containsKey('data') &&
            data['data'] != null) {
          print('Found nested data structure, extracting inner data');
          // Extract the inner data object
          final innerData = data['data'];

          // Process the inner data
          if (innerData is Map) {
            // Ensure items array exists
            if (!innerData.containsKey('items') || innerData['items'] == null) {
              innerData['items'] = [];
              print('No items found in order, creating empty array');
            } else if (innerData['items'] is List &&
                innerData['items'].isNotEmpty) {
              print('Found ${innerData['items'].length} items in order');
              // Process items (no need to change this part)
            }

            return {
              'success': true,
              'data': innerData,
            };
          }
        }

        // Original processing for non-nested data
        // Ensure items array exists
        if (!data.containsKey('items') || data['items'] == null) {
          data['items'] = [];
          print('No items found in order, creating empty array');
        } else if (data['items'] is List && data['items'].isNotEmpty) {
          // Process each item to ensure complete product information
          List<dynamic> items = data['items'];
          List<dynamic> enhancedItems = [];

          for (int i = 0; i < items.length; i++) {
            var item = items[i];

            // If product is just an ID, fetch the full product details
            if (item['product'] != null && item['product'] is String) {
              String productId = item['product'];
              print('Fetching details for product ID: $productId');

              try {
                final productResponse = await getProduct(productId);
                if (productResponse['success'] &&
                    productResponse['data'] != null) {
                  // Replace the product ID with the full product object
                  Map<String, dynamic> enhancedItem =
                      Map<String, dynamic>.from(item);
                  enhancedItem['product'] = productResponse['data'];
                  print(
                      'Enhanced item with product details: ${productResponse['data']['name']}');
                  enhancedItems.add(enhancedItem);
                } else {
                  // If product fetch fails, keep original data but add a name
                  Map<String, dynamic> enhancedItem =
                      Map<String, dynamic>.from(item);
                  if (!enhancedItem.containsKey('name')) {
                    enhancedItem['name'] = 'Product #$productId';
                  }
                  if (!enhancedItem.containsKey('productName')) {
                    enhancedItem['productName'] = 'Product #$productId';
                  }
                  print(
                      'Could not fetch product details, using placeholder name');
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
          data['items'] = enhancedItems;
        }

        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to fetch order details',
        };
      }
    } catch (e) {
      print('Error fetching order: $e');
      return {
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      print('Creating new order with total: ${orderData['totalAmount']}');

      // Format items to ensure proper structure
      if (orderData.containsKey('items') && orderData['items'] is List) {
        List<dynamic> items = orderData['items'];
        List<dynamic> formattedItems = [];

        for (int i = 0; i < items.length; i++) {
          var item = items[i];
          Map<String, dynamic> formattedItem = Map<String, dynamic>.from(item);

          // Handle product ID
          if (item.containsKey('product')) {
            if (item['product'] is Map) {
              formattedItem['product'] = item['product']['_id'];
            } else if (item['product'] is String) {
              formattedItem['product'] = item['product'];
            }
          }

          // Handle measurements - create a new measurement document first
          if (item.containsKey('measurements') && item['measurements'] is Map) {
            try {
              // Create a new measurement document
              final measurementData = {
                'customer': orderData['customer'],
                'category': item['product'] is Map
                    ? item['product']['category']['_id']
                    : null,
                'values': item['measurements'],
                'notes': item['notes'] ?? '',
              };

              final measurementResponse =
                  await _post('/measurements', body: measurementData);

              if (measurementResponse['success'] == true &&
                  measurementResponse['data'] != null) {
                // Use the new measurement ID
                formattedItem['measurements'] =
                    measurementResponse['data']['_id'];
              } else {
                print(
                    'Failed to create measurement: ${measurementResponse['error']}');
                formattedItem['measurements'] = null;
              }
            } catch (e) {
              print('Error creating measurement: $e');
              formattedItem['measurements'] = null;
            }
          }

          // Remove any extra fields that shouldn't be sent to the API
          formattedItem.remove('productName');
          formattedItem.remove('productDescription');

          // Ensure required fields
          if (!formattedItem.containsKey('quantity')) {
            formattedItem['quantity'] = 1;
          }
          if (!formattedItem.containsKey('price')) {
            formattedItem['price'] = 0.0;
          }

          formattedItems.add(formattedItem);
        }

        // Update the items in orderData
        orderData['items'] = formattedItems;
      }

      // Remove any extra fields from the order data
      orderData.remove('createdBy');
      orderData.remove('updatedBy');
      orderData.remove('createdAt');
      orderData.remove('updatedAt');
      orderData.remove('__v');

      // Call the API
      final response = await _post('/orders', body: orderData);

      // Log the response
      print('Create order API response: ${json.encode(response)}');

      if (response['success'] == true) {
        // Handle nested response structure
        var orderData = response['data'];
        if (orderData is Map &&
            orderData.containsKey('success') &&
            orderData.containsKey('data')) {
          orderData = orderData['data'];
        }

        if (orderData != null && orderData['_id'] != null) {
          final orderId = orderData['_id'];
          print('Order saved successfully with ID: $orderId');

          // Get the full order details
          final orderDetails = await getOrder(orderId);
          return orderDetails;
        } else {
          print('Order ID not found in response');
          return {
            'success': false,
            'error': 'Order ID not found in response',
          };
        }
      }

      return response;
    } catch (e) {
      print('Error in createOrder: $e');
      return {
        'success': false,
        'error': 'Exception during order creation: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateOrder(
      String id, Map<String, dynamic> orderData) async {
    try {
      print('=== UPDATE ORDER REQUEST ===');
      print('Order ID: $id');
      print('Original order data: ${json.encode(orderData)}');

      // Ensure items have proper product IDs
      if (orderData.containsKey('items') && orderData['items'] is List) {
        List<dynamic> items = orderData['items'];
        List<dynamic> formattedItems = [];

        for (int i = 0; i < items.length; i++) {
          var item = items[i];
          print('\nProcessing item $i: ${json.encode(item)}');

          Map<String, dynamic> formattedItem = Map<String, dynamic>.from(item);

          // Handle product ID
          if (item.containsKey('product')) {
            if (item['product'] is Map) {
              formattedItem['product'] = item['product']['_id'];
              print(
                  'Product is Map, extracted ID: ${formattedItem['product']}');
            } else if (item['product'] is String) {
              // Validate product ID exists
              try {
                final productResponse = await getProduct(item['product']);
                if (!productResponse['success']) {
                  print('Product not found, skipping item');
                  continue; // Skip this item if product doesn't exist
                }
                formattedItem['product'] = item['product'];
                print('Product is String ID: ${formattedItem['product']}');
              } catch (e) {
                print('Error validating product: $e');
                continue; // Skip this item if validation fails
              }
            }
          }

          // Handle measurements
          if (item.containsKey('measurements')) {
            if (item['measurements'] is Map) {
              // If measurements is a map, create a new measurement
              try {
                final measurementData = {
                  'customer': orderData['customer'],
                  'category': item['product'] is Map
                      ? item['product']['category']['_id']
                      : null,
                  'values': item['measurements'],
                  'notes': item['notes'] ?? '',
                };

                final measurementResponse =
                    await _post('/measurements', body: measurementData);

                if (measurementResponse['success'] == true &&
                    measurementResponse['data'] != null) {
                  formattedItem['measurements'] =
                      measurementResponse['data']['_id'];
                  print(
                      'Created new measurement: ${formattedItem['measurements']}');
                } else {
                  print('Failed to create measurement, setting to null');
                  formattedItem['measurements'] = null;
                }
              } catch (e) {
                print('Error creating measurement: $e');
                formattedItem['measurements'] = null;
              }
            } else if (item['measurements'] is String) {
              formattedItem['measurements'] = item['measurements'];
              print(
                  'Measurements is String ID: ${formattedItem['measurements']}');
            }
          }

          // Remove any extra fields that shouldn't be sent to the API
          formattedItem.remove('productName');
          formattedItem.remove('productDescription');

          // Ensure required fields
          if (!formattedItem.containsKey('quantity')) {
            formattedItem['quantity'] = 1;
          }
          if (!formattedItem.containsKey('price')) {
            formattedItem['price'] = 0.0;
          }

          print('Formatted item: ${json.encode(formattedItem)}');
          formattedItems.add(formattedItem);
        }

        // If no valid items remain, return error
        if (formattedItems.isEmpty) {
          return {
            'success': false,
            'error': 'No valid items to update',
          };
        }

        // Update the items in orderData
        orderData['items'] = formattedItems;
      }

      // Remove any extra fields from the order data
      orderData.remove('customer');
      orderData.remove('createdBy');
      orderData.remove('updatedBy');
      orderData.remove('createdAt');
      orderData.remove('updatedAt');
      orderData.remove('__v');

      print('\nFinal order data being sent: ${json.encode(orderData)}');

      // Call the API
      final response = await _put('/orders/$id', body: orderData);

      print('\nAPI Response: ${json.encode(response)}');

      // If successful, get the updated order details to ensure everything is synced
      if (response['success'] == true) {
        final updatedOrder = await getOrder(id);
        print('\nRetrieved updated order: ${updatedOrder['data'] != null}');
        print('Updated order data: ${json.encode(updatedOrder['data'])}');

        if (updatedOrder['success'] == true) {
          return {
            'success': true,
            'data': updatedOrder['data'],
          };
        }
      }

      return response;
    } catch (e) {
      print('Error in updateOrder: $e');
      return {
        'success': false,
        'error': 'Exception during order update: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String id, String status) async {
    return await _put('/orders/$id/status', body: {'status': status});
  }

  // Create a test order with sample items (for debugging)
  Future<Map<String, dynamic>> createTestOrder() async {
    try {
      // First get a customer to assign to the order
      final customersResult = await getCustomers(limit: 1);
      if (!customersResult['success'] ||
          customersResult['data'] == null ||
          (customersResult['data'] is List &&
              customersResult['data'].isEmpty)) {
        return {'success': false, 'error': 'No customers available'};
      }

      String customerId = '';
      if (customersResult['data'] is List) {
        customerId = customersResult['data'][0]['_id'];
      } else if (customersResult['data'] is Map &&
          customersResult['data']['data'] is List) {
        customerId = customersResult['data']['data'][0]['_id'];
      }

      if (customerId.isEmpty) {
        return {'success': false, 'error': 'Could not get customer ID'};
      }

      // Next get a product to add to the order
      final productsResult = await getProducts(limit: 1);
      if (!productsResult['success'] ||
          productsResult['data'] == null ||
          (productsResult['data'] is List && productsResult['data'].isEmpty)) {
        return {'success': false, 'error': 'No products available'};
      }

      String productId = '';
      if (productsResult['data'] is List) {
        productId = productsResult['data'][0]['_id'];
      } else if (productsResult['data'] is Map &&
          productsResult['data']['data'] is List) {
        productId = productsResult['data']['data'][0]['_id'];
      }

      if (productId.isEmpty) {
        return {'success': false, 'error': 'Could not get product ID'};
      }

      // Create a test order with these IDs
      final orderData = {
        'customer': customerId,
        'items': [
          {
            'product': productId,
            'quantity': 2,
            'price': 99.99,
            'notes': 'Test item 1 - added for debugging',
          },
          {
            'product': productId,
            'quantity': 1,
            'price': 149.99,
            'notes': 'Test item 2 - added for debugging',
          }
        ],
        'status': 'New',
        'totalAmount': 349.97,
        'dueDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'priority': 'Medium',
        'notes': 'Test order created for debugging',
      };

      print('Creating test order with data: $orderData');
      final result = await createOrder(orderData);

      return result;
    } catch (e) {
      print('Error creating test order: $e');
      return {'success': false, 'error': 'Error creating test order: $e'};
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
    return await _get(
      '/invoices',
      queryParams: {
        'page': page,
        'limit': limit,
        'search': search,
        'customer': customer,
        'status': status,
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    return await _get('/invoices/$id');
  }

  Future<Map<String, dynamic>> createInvoice(
      Map<String, dynamic> invoiceData) async {
    return await _post('/invoices', body: invoiceData);
  }

  Future<Map<String, dynamic>> updateInvoice(
      String id, Map<String, dynamic> invoiceData) async {
    return await _put('/invoices/$id', body: invoiceData);
  }

  Future<Map<String, dynamic>> addPayment(
      String invoiceId, Map<String, dynamic> paymentData) async {
    return await _post('/invoices/$invoiceId/payments', body: paymentData);
  }

  // Generic API request handler with authentication
  Future<Map<String, dynamic>> _getWithAuth(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    return await _get(endpoint, queryParams: queryParams, requireAuth: true);
  }

  // Get order with detailed item information
  Future<Map<String, dynamic>> getDetailedOrderItems(String orderId) async {
    try {
      print('Fetching detailed order items for ID: $orderId');

      // First get the basic order to ensure it exists
      final orderResponse = await _get('/orders/$orderId');

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
}
