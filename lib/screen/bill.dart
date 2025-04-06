import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BillItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final double price;
  final String? imagePath;
  final IconData? icon;
  final Map<String, dynamic>? measurements;

  BillItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    this.imagePath,
    this.icon,
    this.measurements,
  });

  // Calculate the total price for this item
  double get totalPrice => price * quantity;
}

class BillScreen extends StatefulWidget {
  const BillScreen({Key? key}) : super(key: key);

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  int _currentNavIndex = 0;

  // Order data
  String _orderId = '';
  String _orderNumber = '';
  String _customerName = '';
  String _customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
  String _dueDate = '';
  String _status = 'New';
  String _notes = '';
  double _totalAmount = 0.0;
  bool _isLoading = true;

  List<BillItem> _billItems = [];
  final ApiService _apiService = ApiService();

  // Add these as class fields
  String _customerPhone = '';
  String _customerAddress = '';
  String _customerEmail = '';
  String _orderDate = '';
  String _paymentStatus = 'Unpaid';
  final String _businessName = 'SIRI Tailor';
  final String _businessAddress = '123 Fashion Street, Tailorville';
  final String _businessContact = '+91 9876543210';
  Map<String, dynamic> _measurements = {};
  String _pdfPath = '';
  bool _pdfReady = false;

  // Add error message variable to the state
  String _errorMessage = '';

  // Add this flag to ensure we don't fetch multiple times
  bool _detailsFetched = false;

  @override
  void initState() {
    super.initState();
    _orderDate = DateTime.now().toString().split(' ')[0];
    // Don't call _fetchOrderDetails here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch order details after dependencies are ready
    if (!_detailsFetched) {
      _fetchOrderDetails();
      _detailsFetched = true;
    }
  }

  // Add method to check for empty order items and debug
  void _checkEmptyOrder() {
    if (_billItems.isEmpty) {
      print('WARNING: Empty bill items list detected!');
      print('Order ID: $_orderId');
      print('Order Number: $_orderNumber');
      print('Customer: $_customerName');
      print('Total Amount: $_totalAmount');

      // If we have a total amount but no items, create a fallback item
      if (_totalAmount > 0) {
        print('Creating fallback item based on total amount');
        setState(() {
          _billItems.add(BillItem(
            id: 'fallback',
            name: 'Order Item',
            description: 'Details not available',
            quantity: 1,
            price: _totalAmount,
            icon: Icons.shopping_bag,
          ));
        });
      }
    } else {
      print('Bill items list has ${_billItems.length} items');
    }
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Handle both string argument and map argument formats
    final dynamic args = ModalRoute.of(context)!.settings.arguments;
    String? orderId;

    if (args is String) {
      orderId = args;
    } else if (args is Map<String, dynamic>) {
      orderId = args['orderId'];
    }

    print('Fetching order details for ID: $orderId');

    if (orderId != null) {
      // Store the order ID for later use
      _orderId = orderId;

      try {
        final response = await _apiService.getOrder(orderId);
        print('API response for order: $response');

        // Check if we have a nested response structure
        Map<String, dynamic> orderData;
        if (response['success'] == true) {
          if (response['data'] is Map &&
              response['data']['success'] == true &&
              response['data']['data'] is Map) {
            // Doubly nested response
            orderData = response['data']['data'];
            print('Unwrapped nested order data: $orderData');
          } else {
            // Single level of nesting
            orderData = response['data'];
          }

          print('Order data to process: $orderData');

          // Extract customer data
          final customer = orderData['customer'] ?? {};
          print('Customer data: $customer');
          _customerName = customer['name'] ?? 'Customer';
          _customerImage =
              customer['image'] ?? 'https://via.placeholder.com/150';
          _customerAddress = customer['address'] ?? 'No address provided';
          _customerPhone = customer['phone'] ?? 'No phone provided';
          _customerEmail = customer['email'] ?? 'No email provided';

          // Extract order data
          _orderNumber = orderData['orderNumber'] ?? orderId;
          print('Order number: $_orderNumber');

          String dueDateStr = orderData['dueDate'] ?? '';
          if (dueDateStr.isNotEmpty) {
            try {
              _dueDate = DateTime.parse(dueDateStr)
                  .toString()
                  .split(' ')[0]; // Just get the date part
            } catch (e) {
              print('Error parsing date: $e');
              _dueDate = DateTime.now()
                  .add(const Duration(days: 7))
                  .toString()
                  .split(' ')[0];
            }
          } else {
            _dueDate = DateTime.now()
                .add(const Duration(days: 7))
                .toString()
                .split(' ')[0];
          }

          _status = orderData['status'] ?? 'New';
          _notes = orderData['notes'] ?? '';

          // Get the total amount
          _totalAmount = 0.0;
          if (orderData['totalAmount'] != null) {
            if (orderData['totalAmount'] is num) {
              _totalAmount = orderData['totalAmount'].toDouble();
            } else if (orderData['totalAmount'] is String) {
              _totalAmount = double.tryParse(orderData['totalAmount']) ?? 0.0;
            }
          }
          print('Total amount: $_totalAmount');

          // Extract order items
          List<dynamic> items = [];
          if (orderData['items'] != null && orderData['items'] is List) {
            items = orderData['items'];
            print('Order items found: $items');
          }

          List<BillItem> newBillItems = [];
          if (items.isNotEmpty) {
            for (var item in items) {
              print('Processing item: $item');
              final product = item['product'] ?? {};

              // Handle different product data formats
              String name;
              if (product is String) {
                name = 'Product';
              } else if (product is Map) {
                name = product['name'] ?? 'Unknown Product';
                print('Found product: $name, ');
              } else {
                name = 'Unknown Product';
              }

              final description = item['notes'] ?? '';
              int quantity = 1;
              if (item['quantity'] != null) {
                if (item['quantity'] is int) {
                  quantity = item['quantity'];
                } else if (item['quantity'] is String) {
                  quantity = int.tryParse(item['quantity']) ?? 1;
                }
              }

              double price = 0.0;
              if (item['price'] != null) {
                if (item['price'] is num) {
                  price = item['price'].toDouble();
                } else if (item['price'] is String) {
                  price = double.tryParse(item['price']) ?? 0.0;
                }
              } else if (product is Map && product['price'] != null) {
                // Get price from product if not specified in item
                if (product['price'] is num) {
                  price = product['price'].toDouble();
                } else if (product['price'] is String) {
                  price = double.tryParse(product['price']) ?? 0.0;
                }
              }

              newBillItems.add(
                BillItem(
                  id: item['_id'] ?? 'unknown_id',
                  name: name,
                  description: description,
                  price: price,
                  quantity: quantity,
                ),
              );
            }
          } else {
            print('No items found in order');
            // Add a placeholder item if no items are found
            newBillItems.add(
              BillItem(
                id: 'placeholder',
                name: 'No items found',
                description: 'Please check order details',
                price: _totalAmount > 0 ? _totalAmount : 0.0,
                quantity: 1,
              ),
            );
          }

          // Set bill items after creating the list
          setState(() {
            _billItems = newBillItems;
          });

          // Extract measurements
          _measurements = {};
          if (orderData['measurements'] != null) {
            try {
              final measurements = orderData['measurements'];
              if (measurements is Map) {
                measurements.forEach((key, value) {
                  _measurements[key] = value.toString();
                });
                print('Measurements: $_measurements');
              }
            } catch (e) {
              print('Error extracting measurements: $e');
            }
          }

          // Generate PDF after setting all the data
          Future.delayed(const Duration(milliseconds: 500), () {
            _generatePdf();
          });

          setState(() {
            _isLoading = false;
          });
        } else {
          // API call failed, use mock data instead
          print(
              'API call failed with response: ${response['error'] ?? 'Unknown error'}');
          _useMockData(orderId);
        }
      } catch (e) {
        print('Error fetching order details: $e');
        // Use mock data when API fails
        _useMockData(orderId);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No order ID provided';
      });
    }
  }

  // Use mock data when API call fails
  void _useMockData(String orderId) {
    print('Using mock data for order: $orderId');

    // Set mock customer data
    _customerName = 'John Doe';
    _customerImage = 'https://via.placeholder.com/150';
    _customerAddress = '123 Main St, City';
    _customerPhone = '+91 9876543210';
    _customerEmail = 'customer@example.com';

    // Set mock order data
    _orderNumber = 'ORD-${orderId.substring(0, 4)}';
    _dueDate = DateTime.now().add(const Duration(days: 7)).toString();
    _status = 'New';
    _notes = 'This is a mock order created when API call failed';
    _totalAmount = 1500.0;

    // Add mock items
    List<BillItem> mockItems = [
      BillItem(
        id: 'mock1',
        name: 'Formal Shirt',
        description: 'White formal shirt with measurements',
        price: 800.0,
        quantity: 1,
      ),
      BillItem(
        id: 'mock2',
        name: 'Trousers',
        description: 'Black formal trousers',
        price: 700.0,
        quantity: 1,
      ),
    ];

    // Add mock measurements
    _measurements = {
      'Chest': '40 in',
      'Shoulder': '18 in',
      'Sleeve': '24 in',
      'Waist': '32 in',
    };

    setState(() {
      _billItems = mockItems;
      _isLoading = false;
    });

    _generatePdf();
  }

  Future<void> _processDirectOrderData(Map<String, dynamic> orderData) async {
    print('Direct order data: $orderData');

    // Process customer data
    final customer = orderData['customer'];
    String customerName = 'Unknown Customer';
    String customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
    String customerPhone = '';
    String customerEmail = '';
    String customerAddress = '';

    if (customer != null) {
      if (customer is Map<String, dynamic>) {
        customerName = customer['name'] ?? 'Unknown Customer';
        customerPhone = customer['phone'] ?? '';
        customerEmail = customer['email'] ?? '';
        customerAddress = customer['address'] ?? '';

        // If customer has an ID, fetch complete details
        if (customer['_id'] != null) {
          final customerResult =
              await _apiService.getCustomerById(customer['_id']);
          if (customerResult['success'] && customerResult['data'] != null) {
            final fullCustomerData = customerResult['data'];
            customerName = fullCustomerData['name'] ?? customerName;
            customerPhone = fullCustomerData['phone'] ?? customerPhone;
            customerEmail = fullCustomerData['email'] ?? customerEmail;
            customerAddress = fullCustomerData['address'] ?? customerAddress;
          }
        }
      }
    }

    // Parse order items
    List<BillItem> items = [];
    Map<String, dynamic> measurements = {};

    if (orderData['items'] != null && orderData['items'] is List) {
      print('Order items found: ${orderData['items']}');

      for (var item in orderData['items']) {
        print('Processing item: $item');

        // Try to get product details
        final product = item['product'];
        String productName = 'Unknown Product';
        String productDescription = '';
        Map<String, dynamic>? itemMeasurements;

        if (product != null) {
          if (product is Map<String, dynamic>) {
            productName = product['name'] ?? 'Unknown Product';
            productDescription = product['description'] ?? '';
            print('Found product: $productName, $productDescription');
          } else if (product is String) {
            // Sometimes the product might be just an ID string
            productName = 'Product ID: $product';
            print('Product is a string ID: $product');

            // Try to fetch product details if we have just an ID
            try {
              final productResult = await _apiService.getProduct(product);
              if (productResult['success'] && productResult['data'] != null) {
                final productData = productResult['data'];
                productName = productData['name'] ?? 'Unknown Product';
                productDescription = productData['description'] ?? '';
                print(
                    'Fetched product details: $productName, $productDescription');
              }
            } catch (e) {
              print('Error fetching product details: $e');
            }
          }
        }

        // If we still don't have a product name, check if the item itself has name/description
        if (productName == 'Unknown Product' &&
            item.containsKey('productName')) {
          productName = item['productName'] ?? 'Unknown Product';
        }

        if (productDescription.isEmpty &&
            item.containsKey('productDescription')) {
          productDescription = item['productDescription'] ?? '';
        }

        // Get measurements
        if (orderData['measurements'] is Map) {
          measurements = Map<String, dynamic>.from(orderData['measurements']);
        }
        // Also check item measurements if available
        if (item['measurements'] is Map) {
          itemMeasurements = Map<String, dynamic>.from(item['measurements']);
          // Add to main measurements collection
          measurements.addAll(itemMeasurements ?? {});
        }

        items.add(BillItem(
          id: item['_id'] ?? '',
          name: productName,
          description: productDescription,
          quantity: item['quantity'] ?? 1,
          price: (item['price'] is num) ? item['price'].toDouble() : 0.0,
          icon: _getIconForProduct(productName),
          measurements: itemMeasurements,
        ));
      }
    } else {
      print('No items found in order data or invalid format');
    }

    // Parse date
    String orderDate = '';
    if (orderData['createdAt'] != null) {
      orderDate = _formatFullDate(orderData['createdAt']);
    } else {
      orderDate = _formatFullDate(DateTime.now().toIso8601String());
    }

    // Update state with order data
    setState(() {
      _orderNumber = orderData['orderNumber'] ?? '';
      _customerName = customerName;
      _customerImage = customerImage;
      _customerPhone = customerPhone;
      _customerEmail = customerEmail;
      _customerAddress = customerAddress;
      _dueDate = _formatDate(orderData['dueDate']);
      _orderDate = orderDate;
      _status = orderData['status'] ?? 'New';
      _notes = orderData['notes'] ?? '';
      _paymentStatus = orderData['paymentStatus'] ?? 'Unpaid';
      _billItems.clear();
      _billItems.addAll(items);
      _measurements = measurements;
      _totalAmount = (orderData['totalAmount'] is num)
          ? orderData['totalAmount'].toDouble()
          : _calculateTotal();
    });
  }

  Future<void> _fetchOrderFromApi(String orderId) async {
    final result = await _apiService.getOrder(orderId);
    print('API response for order: $result');

    if (!result['success']) {
      print('API returned error or no data: ${result['error']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to load order details'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      _loadSampleData();
      return;
    }

    // Handle nested data structure that might be returned from the API
    final Map<String, dynamic> orderData;
    if (result['data'] is Map &&
        result['data'].containsKey('success') &&
        result['data'].containsKey('data') &&
        result['data']['data'] is Map) {
      // Handle double-nested data: {success: true, data: {success: true, data: {...}}}
      orderData = result['data']['data'];
      print('Unwrapped nested order data: $orderData');
    } else {
      // Standard format: {success: true, data: {...}}
      orderData = result['data'];
    }

    print('Order data to process: $orderData');

    // Process the order data
    await _processDirectOrderData(orderData);
  }

  String _formatFullDate(dynamic date) {
    try {
      if (date == null) return 'No date';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'Invalid date';
      }

      // Format as DD MMM YYYY
      final List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'No date';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'Invalid date';
      }

      // Format as MMM DD
      final List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getIconForProduct(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('shirt') || name.contains('blouse')) {
      return Icons.dry_cleaning;
    } else if (name.contains('suit') || name.contains('blazer')) {
      return Icons.business;
    } else if (name.contains('pant') || name.contains('trouser')) {
      return Icons.accessibility_new;
    } else if (name.contains('dress') || name.contains('lehenga')) {
      return Icons.checkroom;
    } else {
      return Icons.design_services;
    }
  }

  void _loadSampleData() {
    // Provide some sample data for demo purposes
    setState(() {
      _orderNumber = '#20255001';
      _customerName = 'John Smith';
      _customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
      _customerPhone = '+91 9876543210';
      _customerEmail = 'john.smith@example.com';
      _customerAddress = '42 Main Street, Anytown, IN 400001';
      _dueDate = 'Jan 15';
      _orderDate = '10 January 2023';
      _status = 'In Progress';
      _paymentStatus = 'Partially Paid';
      _notes = 'Customer requested express tailoring with premium fabric.';

      // Sample measurements
      _measurements = {
        'Chest': '40 in',
        'Waist': '36 in',
        'Shoulder': '18 in',
        'Sleeve': '24 in',
        'Length': '30 in',
      };

      // Sample bill items
      _billItems.clear();
      _billItems.addAll([
        BillItem(
          id: '1',
          name: 'Formal Shirt',
          description: 'Cotton, White',
          quantity: 2,
          price: 85.00,
          icon: Icons.checkroom,
          measurements: {
            'Neck': '16 in',
            'Chest': '40 in',
            'Sleeve': '24 in',
          },
        ),
        BillItem(
          id: '2',
          name: 'Suit Vest',
          description: 'Black, Slim Fit',
          quantity: 1,
          price: 120.00,
          icon: Icons.dry_cleaning,
          measurements: {
            'Chest': '40 in',
            'Waist': '36 in',
            'Length': '26 in',
          },
        ),
      ]);

      _totalAmount = _calculateTotal();
    });
  }

  double _calculateTotal() {
    return _billItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in bill.dart: $index');

    // Don't navigate if already on the selected page
    if (index == _currentNavIndex) {
      print('Already on this page, not navigating');
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });

    // Get the route from the AppBottomNav
    final String route = AppBottomNav.getRouteForIndex(index);
    print('Navigating to route: $route');

    // Navigate to the selected route and clear the navigation stack
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notification functionality
  }

  // Send receipt on WhatsApp
  Future<void> _sendOnWhatsApp() async {
    try {
      if (_customerPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer phone number not available'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        return;
      }

      // Format phone number for WhatsApp (remove spaces, ensure starts with country code)
      String phoneNumber = _customerPhone.replaceAll(' ', '');
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+91$phoneNumber'; // Default to India if no country code
      }

      // Remove any '+' as WhatsApp URL doesn't use it
      phoneNumber = phoneNumber.replaceAll('+', '');

      // Create a message with invoice details
      String message = '''
*INVOICE: #$_orderNumber*
Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
Customer: $_customerName

Total Amount: ₹${_totalAmount.toStringAsFixed(2)}
Status: ${_paymentStatus.toUpperCase()}

Please complete the payment. Thank you for your business!
      ''';

      // Encode the message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // Create WhatsApp URL
      String whatsappURL = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      // Launch WhatsApp
      if (await canLaunch(whatsappURL)) {
        await launch(whatsappURL);
      } else {
        // Fallback if WhatsApp can't be launched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Is it installed?'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending WhatsApp message: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  // This would be the implementation for Twilio/Gupshup integration
  // This is a placeholder and should be implemented with actual API calls
  Future<void> _sendWhatsAppViaTwilio() async {
    try {
      // Example implementation for Twilio API (would need to be implemented on backend)
      // This is just a placeholder showing what the payload might look like

      final payload = {
        'to': _customerPhone,
        'orderNumber': _orderNumber,
        'customerName': _customerName,
        'amount': _totalAmount,
        'status': _status,
        'paymentStatus': _paymentStatus,
        'messageType':
            'invoice', // Other types could be 'payment_reminder', 'status_update', etc.
      };

      // In reality, this would be an API call to your backend that interfaces with Twilio/Gupshup
      // final response = await _apiService.sendWhatsAppMessage(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp message sent successfully'),
          backgroundColor: AppTheme.statusInProgress,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending WhatsApp message: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  void _navigateToEditOrder() {
    Navigator.pushNamed(
      context,
      '/new_order',
      arguments: {
        'isEditing': true,
        'orderId': _orderId,
        'customerName': _customerName,
        'customerPhone': _customerPhone,
        'customerId': '', // We don't have this in our current state
        'measurements': _measurements,
        'orderData': {
          'status': _status,
          'notes': _notes,
          'totalAmount': _totalAmount,
          'dueDate': _dueDate,
          'items': _billItems
              .map((item) => {
                    'id': item.id,
                    'name': item.name,
                    'description': item.description,
                    'quantity': item.quantity,
                    'price': item.price,
                  })
              .toList(),
        },
      },
    ).then((_) {
      // Refresh bill details when returning from edit screen
      _fetchOrderDetails();
    });
  }

  void _navigateToOrderDetail() {
    // Save the orderId before navigating
    final String orderIdToUse = _orderId;

    print('Navigating to order detail with ID: $orderIdToUse');

    // Navigate to order detail screen with ID directly as a string parameter
    Navigator.pushNamed(context, '/order_detail', arguments: orderIdToUse);
  }

  // Add this method to mark order as paid and completed
  Future<void> _markOrderAsPaid() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only allow marking as paid if status is Ready
      if (_status != 'Ready') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Only orders with "Ready" status can be marked as paid'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update the order status to Completed
      final response =
          await _apiService.updateOrderStatus(_orderId, 'Completed');
      print('Update order status response: $response');

      if (response['success']) {
        // Update local state
        setState(() {
          _status = 'Completed';
          _paymentStatus = 'Paid';
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as paid and completed'),
            backgroundColor: Colors.green,
          ),
        );

        // Re-generate PDF with updated status
        _generatePdf();
      } else {
        throw Exception(response['error'] ?? 'Failed to update order status');
      }
    } catch (e) {
      print('Error marking order as paid: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from auth provider
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : Column(
                children: [
                  // User profile header
                  UserProfileHeader(
                    name: userData['name'] ?? 'Tailor',
                    role: userData['role'] ?? 'User',
                    profileImageUrl: userData['profileImage'] ??
                        'https://randomuser.me/api/portraits/men/32.jpg',
                    onProfileTap: _navigateToProfile,
                    onNotificationTap: _showNotifications,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Summary Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppTheme.paddingMedium),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _orderNumber,
                                      style: AppTheme.headingLarge,
                                    ),
                                    const SizedBox(
                                        height: AppTheme.paddingSmall),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_billItems.length} ${_billItems.length == 1 ? 'Item' : 'Items'} • Due $_dueDate',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Edit button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: AppTheme.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: _navigateToEditOrder,
                                              tooltip: 'Edit Order',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            const SizedBox(
                                                width: AppTheme.paddingMedium),
                                            // Share button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.share,
                                                color: AppTheme.textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: _downloadPdf,
                                              tooltip: 'Share Invoice',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: AppTheme.paddingMedium),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_status)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _getStatusColor(_status),
                                        ),
                                      ),
                                      child: Text(
                                        _status,
                                        style: TextStyle(
                                          color: _getStatusColor(_status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppTheme.paddingMedium),
                                    // Payment status badge
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _paymentStatus == 'Paid'
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: _paymentStatus == 'Paid'
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          child: Text(
                                            _paymentStatus,
                                            style: TextStyle(
                                              color: _paymentStatus == 'Paid'
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),

                                        // Mark as Paid button - only show if status is Ready
                                        if (_status == 'Ready' &&
                                            _paymentStatus != 'Paid')
                                          ElevatedButton.icon(
                                            onPressed: _markOrderAsPaid,
                                            icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 16),
                                            label: const Text('Mark as Paid'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              textStyle:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: AppTheme.paddingMedium),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              NetworkImage(_customerImage),
                                          onBackgroundImageError: (_, __) {
                                            // Fallback for image loading error
                                          },
                                          child: const Icon(Icons.person,
                                              color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(
                                            width: AppTheme.paddingSmall),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _customerName,
                                                style: AppTheme.bodyLarge,
                                              ),
                                              const SizedBox(
                                                  height:
                                                      AppTheme.paddingSmall),
                                              Text(
                                                _customerPhone,
                                                style: AppTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_customerAddress.isNotEmpty ||
                                        _customerEmail.isNotEmpty) ...[
                                      const SizedBox(
                                          height: AppTheme.paddingSmall),
                                      const Divider(
                                          color: AppTheme.dividerColor),
                                      const SizedBox(
                                          height: AppTheme.paddingSmall),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 14,
                                              color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _customerAddress.isNotEmpty
                                                  ? _customerAddress
                                                  : 'No address provided',
                                              style: AppTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_customerEmail.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined,
                                                size: 14,
                                                color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _customerEmail,
                                                style: AppTheme.bodySmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                    const SizedBox(
                                        height: AppTheme.paddingSmall),
                                    const Divider(color: AppTheme.dividerColor),
                                    const SizedBox(
                                        height: AppTheme.paddingSmall),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 14,
                                                color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Order Date: $_orderDate',
                                              style: AppTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _paymentStatus == 'Paid'
                                                ? const Color(0x3310B981)
                                                : (_paymentStatus == 'Unpaid'
                                                    ? const Color(0x33DC2626)
                                                    : const Color(0x33F59E0B)),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _paymentStatus,
                                            style: TextStyle(
                                              color: _paymentStatus == 'Paid'
                                                  ? const Color(0xFF10B981)
                                                  : (_paymentStatus == 'Unpaid'
                                                      ? const Color(0xFFDC2626)
                                                      : const Color(
                                                          0xFFF59E0B)),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Card for buttons with full width
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppTheme.paddingMedium),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // View Order Details button
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _navigateToOrderDetail,
                                        icon: const Icon(Icons.info_outline),
                                        label: const Text('Order Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primary.withOpacity(0.1),
                                          foregroundColor: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppTheme.paddingMedium),
                                    // Share PDF button
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _downloadPdf,
                                        icon: const Icon(Icons.picture_as_pdf),
                                        label: const Text('Save PDF'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppTheme.paddingMedium),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice Items',
                                      style: AppTheme.headingMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: AppTheme.paddingMedium),

                                    // Order items list
                                    _billItems.isEmpty
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                  AppTheme.paddingMedium),
                                              child: Text(
                                                'No items in this order',
                                                style: AppTheme.bodyRegular,
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              ...List.generate(
                                                _billItems.length,
                                                (index) => _buildBillItemRow(
                                                    _billItems[index],
                                                    index ==
                                                        _billItems.length - 1),
                                              ),

                                              const Divider(
                                                  color: AppTheme.dividerColor),

                                              // Subtotal
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: AppTheme
                                                            .paddingSmall),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Subtotal',
                                                      style: AppTheme.bodyMedium
                                                          .copyWith(
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                                      style: AppTheme.bodyMedium
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Total
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: AppTheme.paddingSmall),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Total',
                                                      style: AppTheme
                                                          .headingMedium,
                                                    ),
                                                    Text(
                                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                                      style: AppTheme
                                                          .headingMedium,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            // Measurements section
                            if (_measurements.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.paddingLarge),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppTheme.paddingMedium),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Measurements',
                                        style: AppTheme.headingMedium,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.paddingMedium),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _measurements.entries
                                            .map((entry) => Container(
                                                  width: 100,
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: AppTheme
                                                            .dividerColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        entry.key,
                                                        style: AppTheme
                                                            .bodySmall
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${entry.value}',
                                                        style: AppTheme
                                                            .bodyRegular,
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Notes section
                            if (_notes.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.paddingLarge),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppTheme.paddingMedium),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Notes',
                                        style: AppTheme.headingMedium,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.paddingMedium),
                                      Text(
                                        _notes,
                                        style: AppTheme.bodyRegular,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Action Buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildBillItemRow(BillItem item, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    item.icon ?? Icons.inventory_2,
                    size: 24,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${item.description} (Qty: ${item.quantity})',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.paddingSmall),
              Expanded(
                flex: 1,
                child: Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: AppTheme.dividerColor),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'New':
        backgroundColor = const Color(0x33DC2626);
        textColor = const Color(0xFFDC2626);
        break;
      case 'In Progress':
        backgroundColor = const Color(0x3310B981);
        textColor = const Color(0xFF10B981);
        break;
      case 'Ready':
        backgroundColor = const Color(0x333B82F6);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'Completed':
        backgroundColor = const Color(0x33059669);
        textColor = const Color(0xFF059669);
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // Generate and save PDF bill
  Future<void> _generatePdf() async {
    if (!mounted) {
      print('_generatePdf called when widget is not mounted, aborting');
      return;
    }

    try {
      print('Starting PDF generation');

      pw.Font? ttf;
      pw.Font? ttfBold;

      try {
        // Try to load custom fonts but use a more robust error handling approach
        ByteData fontData =
            await rootBundle.load("assets/fonts/Inter-Regular.ttf");
        ByteData fontBoldData =
            await rootBundle.load("assets/fonts/Inter-Bold.ttf");

        // Use default built-in fonts instead of attempting to load custom TTF
        // This bypasses the TTF parser error and uses PDF built-in fonts
        ttf = null;
        ttfBold = null;

        print('Loaded custom fonts for PDF');
      } catch (e) {
        print('Error loading custom fonts: $e');
        print('Using fallback fonts');
      }

      final pw.Document pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Invoice header with your business info and customer info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Business info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _businessName,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _businessAddress,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Contact: $_businessContact',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),

                  // Invoice details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Order: #$_orderNumber',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Due Date: $_dueDate',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.red,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'UNPAID',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 8,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Customer details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _customerName,
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _customerAddress,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Phone: $_customerPhone',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Email: $_customerEmail',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Invoice items table
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5), // Make item name column wider
                  1: const pw.FlexColumnWidth(1), // Quantity is small
                  2: const pw.FlexColumnWidth(2), // Rate needs more space
                  3: const pw.FlexColumnWidth(2), // Amount needs more space
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Item & Description',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Rate',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Table rows for each item
                  ..._billItems.map((item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  item.description.isNotEmpty
                                      ? item.description
                                      : 'Standard',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${item.quantity}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      )),

                  // Total row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total:',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (_measurements.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Measurements',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _measurements.entries.map((entry) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entry.key,
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${entry.value}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              pw.SizedBox(height: 40),

              // Terms and signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: 200,
                        child: pw.Text(
                          'Payment is due within 15 days. Please make checks payable to SIRI Tailor.',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 50,
                        width: 200,
                        child: pw.Center(
                          child: pw.Text(
                            'Authorized Signature',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 200,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.grey300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      print('PDF document created successfully');
      // Save PDF
      final output = await getTemporaryDirectory();
      final tempDir = output.path;
      print('Temporary directory path: $tempDir');

      // Make sure the path exists
      final pdfDir = Directory(tempDir);
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
        print('Created directory: $tempDir');
      }

      final file =
          File('$tempDir/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
      print('Saving PDF to path: ${file.path}');
      await file.writeAsBytes(await pdf.save());
      _pdfPath = file.path;
      print('PDF saved to path: $_pdfPath');

      // Update the UI after PDF generation
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pdfReady = true;
        });
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error generating invoice: $e';
        });
      }
    }
  }

  // Download PDF and share
  Future<void> _downloadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Starting PDF download process');

      // Generate the PDF
      await _generatePdf();

      // Wait a moment to ensure PDF is generated
      await Future.delayed(const Duration(milliseconds: 500));

      if (_pdfPath.isEmpty) {
        throw Exception('PDF generation failed - path is empty');
      }

      final file = File(_pdfPath);

      if (!await file.exists()) {
        throw Exception('PDF file not found at path: $_pdfPath');
      }

      print(
          'PDF file exists at: $_pdfPath with size: ${await file.length()} bytes');

      setState(() {
        _isLoading = false;
      });

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice $_orderNumber',
      );

      print('Share result: $result');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error generating PDF: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppTheme.accentColor,
          duration: const Duration(seconds: 5),
        ),
      );
      print('Error generating PDF: $e');
    }
  }

  // Share PDF method
  Future<void> _sharePdf() async {
    if (_pdfPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not available yet. Please wait.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    try {
      final file = File(_pdfPath);
      await Share.shareXFiles([XFile(_pdfPath)],
          text: 'Invoice for Order #$_orderNumber');
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return const Color(0xFF10B981); // Green
      case 'Ready':
        return const Color(0xFF3B82F6); // Blue
      case 'Completed':
        return const Color(0xFF059669); // Dark Green
      case 'Urgent':
        return const Color(0xFFDC2626); // Red
      case 'New':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // WhatsApp button (replacing Share button)
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _sendOnWhatsApp,
              icon: const Icon(Icons.chat,
                  size:
                      18), // Using chat icon as WhatsApp icon is not in Flutter's built-in icons
              label: Text('WhatsApp',
                  style: AppTheme.bodyRegular.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          // Mark as paid button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _status == 'Completed'
                    ? Colors.grey
                    : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _status == 'Completed' ? null : _markOrderAsPaid,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                _status == 'Completed' ? 'Paid' : 'Mark as Paid',
                style: AppTheme.bodyRegular
                    .copyWith(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit order button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _navigateToEditOrder,
              icon: const Icon(Icons.edit, size: 18),
              label: Text('Edit',
                  style: AppTheme.bodyRegular.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
