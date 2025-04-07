import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrderItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final double price;
  final IconData icon;

  OrderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.icon,
  });
}

class ChecklistItem {
  final String title;
  bool isCompleted;

  ChecklistItem({
    required this.title,
    required this.isCompleted,
  });
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  int _currentNavIndex = 0;

  // Order data fields
  String _orderId = '';
  String _orderNumber = '';
  String _customerName = '';
  String _customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
  String _dueDate = '';
  int _itemCount = 0;
  String _status = 'New';
  String _priority = 'Medium';
  String _notes = '';
  bool _isLoading = true;
  double _totalAmount = 0.0;

  final List<OrderItem> _orderItems = [];

  // Default checklist items - will be updated based on order type
  final List<ChecklistItem> _checklistItems = [
    ChecklistItem(title: 'Measurements Confirmed', isCompleted: false),
    ChecklistItem(title: 'Material Selected', isCompleted: false),
    ChecklistItem(title: 'Cutting Complete', isCompleted: false),
    ChecklistItem(title: 'First Fitting', isCompleted: false),
    ChecklistItem(title: 'Final Adjustments', isCompleted: false),
  ];

  final ApiService _apiService = ApiService();

  bool _detailsFetched = false;
  bool shouldRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay fetch until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrderDetails();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If we should refresh, fetch order details when the app is resumed
      if (shouldRefresh && _orderId.isNotEmpty) {
        print('App resumed with shouldRefresh flag, refreshing order details');
        _fetchOrderDetails();
      }
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    print('didChangeDependencies called in OrderDetailScreen');

    if (!_detailsFetched) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('Order detail arguments: $args');

      if (args is Map<String, dynamic> && args.containsKey('id')) {
        setState(() {
          _orderId = args['id'];
          print('Order ID set: $_orderId');
        });

        // Set shouldRefresh flag if provided
        if (args.containsKey('shouldRefresh')) {
          shouldRefresh = args['shouldRefresh'] ?? false;
          print('Should refresh flag: $shouldRefresh');
        }
      }

      // Fetch the order details now that we have an ID
      if (_orderId.isNotEmpty) {
        print('Fetching order details for ID: $_orderId');
        await _fetchOrderDetails();
      }

      _detailsFetched = true;
    }
  }

  Future<void> _fetchOrderDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      // Clear existing order items to avoid duplication
      _orderItems.clear();
    });

    try {
      // Get the order ID from arguments if available
      final dynamic args = ModalRoute.of(context)?.settings.arguments;

      print('Order detail raw arguments: $args');

      // Handle both string argument and map argument formats
      if (args is String) {
        _orderId = args; // Direct string argument (from bill.dart)
        print('Order ID from direct string argument: $_orderId');
      } else if (args is Map<String, dynamic>) {
        if (args.containsKey('id')) {
          _orderId = args['id'];
        } else if (args.containsKey('orderId')) {
          _orderId = args['orderId'];
        }

        // Check for shouldRefresh flag
        if (args.containsKey('shouldRefresh')) {
          shouldRefresh = args['shouldRefresh'] ?? false;
          print('Setting shouldRefresh flag to: $shouldRefresh');
        }

        print('Order ID from map argument: $_orderId');
      } else {
        print(
            'Warning: Unknown argument type for order details: ${args?.runtimeType}');
      }

      // If we have a valid order ID, fetch from API
      if (_orderId.isNotEmpty) {
        print('Fetching order details for ID: $_orderId');
        // Force a fresh fetch from the server by adding a timestamp
        final result = await _apiService
            .getOrder('$_orderId?t=${DateTime.now().millisecondsSinceEpoch}');
        print('Order API result success: ${result['success']}');

        if (result['success'] && result['data'] != null) {
          final orderData = result['data'];
          print('Order data received: ${orderData.keys}');

          if (orderData['items'] != null) {
            print('Items count: ${orderData['items'].length}');
          } else {
            print('No items in the order data');
          }

          // Extract customer information
          String customerName = 'Unknown Customer';
          String customerImage =
              'https://randomuser.me/api/portraits/men/1.jpg';
          String customerPhone = '';

          // Extract customer data from order
          if (orderData['customer'] != null) {
            print('Customer data type: ${orderData['customer'].runtimeType}');
            if (orderData['customer'] is Map) {
              // Customer is an object
              customerName = orderData['customer']['name'] ?? customerName;
              customerImage = orderData['customer']['image'] ?? customerImage;
              customerPhone = orderData['customer']['phone'] ?? '';
              print(
                  'Customer from object: $customerName, Phone: $customerPhone');
            } else if (orderData['customer'] is String) {
              // Customer is an ID, try to load customer details
              print('Customer is an ID: ${orderData['customer']}');
              try {
                final customerResult =
                    await _apiService.getCustomerById(orderData['customer']);
                if (customerResult['success'] &&
                    customerResult['data'] != null) {
                  final customerData = customerResult['data'];
                  customerName = customerData['name'] ?? customerName;
                  customerImage = customerData['image'] ?? customerImage;
                  customerPhone = customerData['phone'] ?? '';
                  print(
                      'Fetched customer details: $customerName, Phone: $customerPhone');
                }
              } catch (e) {
                print('Error fetching customer details: $e');
              }
            }
          } else {
            print('No customer data in order');
          }

          // Extract items from order
          List<OrderItem> items = [];
          if (orderData['items'] != null && orderData['items'] is List) {
            final itemsList = orderData['items'] as List;
            print('Processing ${itemsList.length} items');

            for (var item in itemsList) {
              print('Processing item: ${item.keys}');
              String productName = 'Unknown Product';
              String productDescription = '';

              // Extract product data (could be a string ID or an object)
              if (item['product'] != null) {
                print('Product data type: ${item['product'].runtimeType}');
                if (item['product'] is Map) {
                  // Product is an object
                  productName = item['product']['name'] ?? productName;
                  productDescription = item['product']['description'] ?? '';
                  print('Product from object: $productName');
                } else if (item['product'] is String) {
                  // Product is an ID - check if we have a name in the item
                  if (item.containsKey('productName')) {
                    productName = item['productName'] ?? productName;
                    print('Product from ID with productName: $productName');
                  } else if (item.containsKey('name')) {
                    productName = item['name'] ?? productName;
                    print('Product from ID with name: $productName');
                  } else {
                    productName = 'Product #${item['product']}';
                    print('Using default product ID as name: $productName');
                  }
                }
              } else {
                print('No product data in item');
              }

              // Check for product description in item
              if (productDescription.isEmpty) {
                if (item.containsKey('description')) {
                  productDescription = item['description'] ?? '';
                } else if (item.containsKey('notes')) {
                  productDescription = item['notes'] ?? '';
                }
              }

              // Get price - try different possible fields
              double price = 0.0;
              if (item.containsKey('price') && item['price'] is num) {
                price = item['price'].toDouble();
              } else if (item.containsKey('unitPrice') &&
                  item['unitPrice'] is num) {
                price = item['unitPrice'].toDouble();
              }

              // Get quantity
              int quantity = 1;
              if (item.containsKey('quantity') && item['quantity'] is num) {
                quantity = item['quantity'];
              }

              items.add(OrderItem(
                id: item['_id'] ?? '',
                name: productName,
                description: productDescription,
                quantity: quantity,
                price: price,
                icon: _getIconForProduct(productName),
              ));
              print('Added item: $productName with price $price');
            }
          } else {
            print('No items found in order data or invalid format');
          }

          // Parse checklist items if available
          _updateChecklistBasedOnStatus(orderData['status'] ?? 'New');

          // Update state with order data
          setState(() {
            _orderNumber = orderData['orderNumber'] ?? '';
            _customerName = customerName;
            _customerImage = customerImage;
            _dueDate = _formatDate(orderData['dueDate']);
            _itemCount = items.length;
            _status = orderData['status'] ?? 'New';
            _priority = orderData['priority'] ?? 'Medium';
            _notes = orderData['notes'] ?? '';
            _orderItems.clear();
            _orderItems.addAll(items);
            _totalAmount = (orderData['totalAmount'] is num)
                ? orderData['totalAmount'].toDouble()
                : 0.0;

            print('Order items count after processing: ${_orderItems.length}');
            print('Total amount: $_totalAmount');
          });

          // Handle empty items - attempt to fetch detailed data if needed
          if (_orderItems.isEmpty) {
            print('No items found, attempting to fetch detailed data');
            await _fetchDetailedOrderItems();
          }

          print('Order details updated in state');
        } else {
          print('Failed to fetch order: ${result['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to load order details'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
      // If no ID, use demo data or show placeholder
      else {
        // For demo purposes, just using some dummy data
        setState(() {
          _orderNumber = 'ORD12345';
          _customerName = 'John Doe';
          _dueDate = '15 April 2023';
          _itemCount = 2;
          _status = 'In Progress';
          _priority = 'High';
          _notes = 'Please deliver ASAP';
          _orderItems.add(
            OrderItem(
              id: '1',
              name: 'Custom Shirt',
              description: 'Blue cotton shirt with custom collar',
              quantity: 1,
              price: 1200.0,
              icon: Icons.dry_cleaning,
            ),
          );
          _orderItems.add(
            OrderItem(
              id: '2',
              name: 'Formal Pants',
              description: 'Black formal pants with pleats',
              quantity: 1,
              price: 1500.0,
              icon: Icons.accessibility_new,
            ),
          );
          _totalAmount = 2700.0;
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // New method to fetch detailed order items
  Future<void> _fetchDetailedOrderItems() async {
    if (_orderId.isEmpty || !mounted) return;

    print('Attempting to fetch detailed product data for order: $_orderId');
    try {
      // First try to get data from the orders endpoint with extra details
      final detailedResult = await _apiService.getDetailedOrderItems(_orderId);

      if (detailedResult['success'] &&
          detailedResult['data'] != null &&
          detailedResult['data']['items'] != null &&
          detailedResult['data']['items'] is List &&
          detailedResult['data']['items'].isNotEmpty) {
        final detailedItems = detailedResult['data']['items'] as List;
        print('Found ${detailedItems.length} detailed items');

        List<OrderItem> newItems = [];
        double totalCalculated = 0.0;

        for (var item in detailedItems) {
          String itemName = 'Unknown Product';
          String itemDesc = '';
          double itemPrice = 0.0;
          int itemQty = 1;

          // Extract product info
          if (item['product'] != null) {
            if (item['product'] is Map) {
              itemName = item['product']['name'] ?? itemName;
              itemDesc = item['product']['description'] ?? '';
            } else if (item.containsKey('productName')) {
              itemName = item['productName'];
            } else if (item.containsKey('name')) {
              itemName = item['name'];
            }
          }

          // Get description
          if (itemDesc.isEmpty) {
            if (item.containsKey('description')) {
              itemDesc = item['description'];
            } else if (item.containsKey('notes')) {
              itemDesc = item['notes'];
            }
          }

          // Get price and quantity
          if (item.containsKey('price') && item['price'] is num) {
            itemPrice = item['price'].toDouble();
          }

          if (item.containsKey('quantity') && item['quantity'] is num) {
            itemQty = item['quantity'];
          }

          // Calculate total
          totalCalculated += (itemPrice * itemQty);

          newItems.add(OrderItem(
            id: item['_id'] ?? '',
            name: itemName,
            description: itemDesc,
            quantity: itemQty,
            price: itemPrice,
            icon: _getIconForProduct(itemName),
          ));
        }

        if (newItems.isNotEmpty && mounted) {
          setState(() {
            _orderItems.addAll(newItems);
            _itemCount = _orderItems.length;

            // Update total if it was zero but we calculated a value
            if (_totalAmount == 0 && totalCalculated > 0) {
              _totalAmount = totalCalculated;
            }
          });

          print(
              'Added ${newItems.length} items from detailed fetch. Total: $_totalAmount');
          return; // Skip the placeholder creation
        }
      }

      // If we're still here, create a placeholder in a separate setState call
      if (mounted && _orderItems.isEmpty) {
        setState(() {
          // If we have a total amount but no items
          if (_totalAmount > 0) {
            print(
                'Creating placeholder item for empty order with amount: $_totalAmount');
            _orderItems.add(OrderItem(
              id: 'placeholder',
              name: 'Order Item',
              description: 'Details not available',
              quantity: 1,
              price: _totalAmount,
              icon: Icons.shopping_bag,
            ));
          } else {
            // If we don't even have a total amount
            print('No total amount, creating default placeholder item');
            _orderItems.add(OrderItem(
              id: 'placeholder',
              name: 'Unknown Item',
              description: 'No details available for this order',
              quantity: 1,
              price: 0.0,
              icon: Icons.help_outline,
            ));
            _totalAmount = 0.0;
          }
          _itemCount = _orderItems.length;
          print('Added placeholder item. New count: ${_orderItems.length}');
        });
      }
    } catch (e) {
      print('Error fetching detailed order data: $e');

      // Add fallback placeholder if needed
      if (mounted && _orderItems.isEmpty) {
        setState(() {
          _orderItems.add(OrderItem(
            id: 'placeholder',
            name: 'Order Item',
            description: 'Error fetching details',
            quantity: 1,
            price: _totalAmount > 0 ? _totalAmount : 0.0,
            icon: Icons.error_outline,
          ));
          _itemCount = 1;
        });
      }
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

  void _updateChecklistBasedOnStatus(String status) {
    switch (status) {
      case 'New':
        // For new orders, just the first item is usually completed
        for (var i = 0; i < _checklistItems.length; i++) {
          _checklistItems[i].isCompleted = i == 0;
        }
        break;
      case 'In Progress':
        // For in-progress orders, first two items are completed
        for (var i = 0; i < _checklistItems.length; i++) {
          _checklistItems[i].isCompleted = i < 2;
        }
        break;
      case 'Ready':
        // For ready orders, all but the last item is completed
        for (var i = 0; i < _checklistItems.length; i++) {
          _checklistItems[i].isCompleted = i < _checklistItems.length - 1;
        }
        break;
      case 'Completed':
        // For completed orders, all items are completed
        for (var item in _checklistItems) {
          item.isCompleted = true;
        }
        break;
      default:
        // Default case
        for (var item in _checklistItems) {
          item.isCompleted = false;
        }
    }
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in order_detail: $index');

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

  Future<void> _updateOrderStatus(String newStatus) async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we're moving from Ready to Completed - ask for payment confirmation
      if (_status == 'Ready' && newStatus == 'Completed') {
        setState(() {
          _isLoading = false;
        });

        // Show payment confirmation dialog
        final bool? isPaid = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text('Payment Confirmation',
                  style: AppTheme.headingMedium),
              content: const Text(
                'Has the customer paid for this order?',
                style: AppTheme.bodyRegular,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );

        // If dialog was dismissed, return early
        if (isPaid == null) return;

        // If not paid, show options to send bill or show QR
        if (!isPaid) {
          final String? action = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.cardBackground,
                title: const Text('Payment Required',
                    style: AppTheme.headingMedium),
                content: const Text(
                  'Would you like to send an invoice or display a payment QR code?',
                  style: AppTheme.bodyRegular,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'cancel'),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () => Navigator.pop(context, 'invoice'),
                    child: const Text('Send Invoice'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    onPressed: () => Navigator.pop(context, 'qr'),
                    child: const Text('Show QR Code'),
                  ),
                ],
              );
            },
          );

          if (action == 'invoice') {
            _navigateToBill();
            return;
          } else if (action == 'qr') {
            _showPaymentQR();
            return;
          } else {
            // User canceled
            return;
          }
        }

        // If we're here, user confirmed payment was made - set loading back to true
        setState(() {
          _isLoading = true;
        });
      }

      // Continue with normal status update
      // If we have a valid order ID, update via API
      if (_orderId.isNotEmpty) {
        final result = await _apiService.updateOrderStatus(_orderId, newStatus);

        if (result['success']) {
          // Update local state
          setState(() {
            _status = newStatus;
            _updateChecklistBasedOnStatus(newStatus);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $newStatus'),
              backgroundColor: AppTheme.statusInProgress,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to update order status'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } else {
        // Demo mode - just update locally
        setState(() {
          _status = newStatus;
          _updateChecklistBasedOnStatus(newStatus);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo: Order status updated to $newStatus'),
            backgroundColor: AppTheme.statusInProgress,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateChecklist(int index, bool value) async {
    // Update local state
    setState(() {
      _checklistItems[index].isCompleted = value;
    });

    // In a real app, you would save this to your backend API
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Marked "${_checklistItems[index].title}" as complete'
            : 'Marked "${_checklistItems[index].title}" as incomplete'),
        duration: const Duration(seconds: 1),
        backgroundColor:
            value ? AppTheme.statusInProgress : AppTheme.accentColor,
      ),
    );
  }

  void _showNotifications() {
    // Implement notification functionality
  }

  void _navigateToEditOrder() {
    Navigator.pushNamed(
      context,
      '/new_order',
      arguments: {
        'isEditing': true,
        'orderId': _orderId,
        'customerName': _customerName,
        'customerPhone': '',
        'customerId': '',
        'orderData': {
          'status': _status,
          'notes': _notes,
          'dueDate': _dueDate,
          'totalAmount': _totalAmount,
          'items': _orderItems
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
      // Refresh order details when returning from edit screen
      shouldRefresh = true;
      _fetchOrderDetails();
    });
  }

  void _navigateToBill() {
    // Navigate to bill/invoice page with the order ID and a refresh flag
    Navigator.pushNamed(
      context,
      '/bill',
      arguments: {
        'orderId': _orderId,
        'shouldRefresh': true, // Flag to indicate data should be refreshed
      },
    ).then((_) {
      // Refresh order details when returning from bill screen
      if (shouldRefresh && mounted) {
        _fetchOrderDetails();
      }
    });
  }

  String _getNextStatus() {
    switch (_status) {
      case 'New':
        return 'In Progress';
      case 'In Progress':
        return 'Ready';
      case 'Ready':
        return 'Completed';
      default:
        return 'Completed';
    }
  }

  Color _getStatusButtonColor() {
    switch (_status) {
      case 'New':
        return const Color(0xFF2563EB);
      case 'In Progress':
        return const Color(0xFF10B981);
      case 'Ready':
        return const Color(0xFFF59E0B);
      case 'Completed':
        return Colors.grey;
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getStatusButtonIcon() {
    switch (_status) {
      case 'New':
        return Icons.play_arrow;
      case 'In Progress':
        return Icons.check_circle_outline;
      case 'Ready':
        return Icons.done_all;
      case 'Completed':
        return Icons.verified;
      default:
        return Icons.play_arrow;
    }
  }

  double get _totalPrice {
    return _orderItems.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Add a method to display payment QR code
  void _showPaymentQR() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Scan to Pay', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Here you would normally display a QR code generated from your payment provider
                // For demo purposes, we're just using a placeholder icon
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 150, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total: ₹${_totalAmount.toStringAsFixed(2)}',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan the QR code to complete payment',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: () {
                Navigator.pop(context);
                // After successful payment, update the status to Completed
                _updateOrderStatus('Completed');
              },
              child: const Text('Payment Received'),
            ),
          ],
        );
      },
    );
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
                            _buildOrderSummaryCard(),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Order Items Card
                            _buildOrderItemsCard(),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Progress Checklist Card
                            _buildProgressChecklistCard(),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Order Notes Card
                            _buildOrderNotesCard(),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Status Update Button (not shown if completed)
                            if (_status != 'Completed')
                              _buildStatusUpdateButton(),

                            const SizedBox(height: AppTheme.paddingLarge),
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

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _orderNumber,
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_itemCount ${_itemCount == 1 ? 'Item' : 'Items'} • Due $_dueDate',
                  style: AppTheme.bodySmall,
                ),
                Row(
                  children: [
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: _navigateToEditOrder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit Order',
                    ),
                    const SizedBox(width: AppTheme.paddingMedium),
                    // Share/Invoice button
                    IconButton(
                      icon: const Icon(Icons.receipt,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: _navigateToBill,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'View Invoice',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(_customerImage),
                  onBackgroundImageError: (_, __) {
                    // Fallback for image loading error
                  },
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Text(
                  _customerName,
                  style: AppTheme.bodyLarge,
                ),
                const Spacer(),
                Row(
                  children: [
                    // Show priority if urgent
                    if (_priority == 'High')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x33DC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _buildStatusBadge(_status),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            _orderItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingMedium),
                      child: Text(
                        'No items in this order',
                        style: AppTheme.bodyRegular,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ...List.generate(
                        _orderItems.length,
                        (index) => _buildOrderItemRow(_orderItems[index],
                            index != _orderItems.length - 1),
                      ),
                      const Divider(color: AppTheme.dividerColor),
                      // Total price
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppTheme.paddingSmall),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: AppTheme.headingMedium,
                            ),
                            Text(
                              '₹${_totalAmount.toStringAsFixed(2)}',
                              style: AppTheme.headingMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 36,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Per piece',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(color: AppTheme.dividerColor),
      ],
    );
  }

  Widget _buildProgressChecklistCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Checklist',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            ...List.generate(
              _checklistItems.length,
              (index) => _buildChecklistItem(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final item = _checklistItems[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: InkWell(
        onTap: () {
          // Toggle checkbox state
          _updateChecklist(index, !item.isCompleted);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  item.isCompleted ? Icons.check : Icons.hourglass_empty,
                  size: 14,
                  color: item.isCompleted ? Colors.green.shade800 : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            Text(
              item.title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            const Spacer(),
            Checkbox(
              value: item.isCompleted,
              onChanged: (value) {
                if (value != null) {
                  _updateChecklist(index, value);
                }
              },
              activeColor: AppTheme.primary,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Notes',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            _notes.isEmpty
                ? const Text(
                    'No notes for this order',
                    style: TextStyle(
                      color: Color(0xFFCBCBCB),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  )
                : Text(
                    _notes,
                    style: const TextStyle(
                      color: Color(0xFFCBCBCB),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateButton() {
    final nextStatus = _getNextStatus();
    final buttonColor = _getStatusButtonColor();
    final buttonIcon = _getStatusButtonIcon();

    String buttonText;

    switch (_status) {
      case 'New':
        buttonText = 'Start Working';
        break;
      case 'In Progress':
        buttonText = 'Mark as Ready';
        break;
      case 'Ready':
        buttonText = 'Mark as Completed';
        break;
      default:
        buttonText = 'Update Status';
    }

    return ElevatedButton(
      onPressed: () => _updateOrderStatus(nextStatus),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [buttonColor, buttonColor.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTheme.paddingSmall),
              Icon(buttonIcon, color: Colors.white),
            ],
          ),
        ),
      ),
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
}
