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
  final String status;

  OrderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.icon,
    this.status = 'New',
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_detailsFetched) {
      print('=== OrderDetailScreen didChangeDependencies ===');
      final args = ModalRoute.of(context)?.settings.arguments;
      print('Route arguments: $args');

      if (args is Map<String, dynamic> && args.containsKey('id')) {
        print('Found order ID in arguments');
        setState(() {
          _orderId = args['id'];
          print('Order ID set: $_orderId');
        });

        // Set shouldRefresh flag if provided
        if (args.containsKey('shouldRefresh')) {
          shouldRefresh = args['shouldRefresh'] ?? false;
          print('Should refresh flag: $shouldRefresh');
        }

        // Fetch the order details now that we have an ID
        if (_orderId.isNotEmpty) {
          print('Initiating order details fetch for ID: $_orderId');
          _fetchOrderDetails();
        } else {
          print('Warning: Empty order ID received');
        }

        _detailsFetched = true;
      } else {
        print('Warning: No order ID found in arguments');
      }
    }
  }

  Future<void> _fetchOrderDetails() async {
    print('=== Starting _fetchOrderDetails ===');
    print('Order ID: $_orderId');
    print('Current loading state: $_isLoading');

    if (!mounted) {
      print('Widget not mounted, skipping fetch');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Calling API service to fetch order details...');
      final result = await _apiService.getOrderById(_orderId, context: context);
      print('API response received: $result');

      if (!mounted) {
        print('Widget not mounted after API call, skipping state update');
        return;
      }

      if (result['success']) {
        print('Successfully fetched order details');
        final orderData = result['data'];
        print('Order data: $orderData');

        final customerData = orderData['customer'] ?? {};
        final items = orderData['items'] ?? [];
        print('Customer data: $customerData');
        print('Items count: ${items.length}');

        // Get customer name and image
        String customerName = 'Unknown Customer';
        String customerImage = 'https://randomuser.me/api/portraits/men/32.jpg';

        if (customerData is Map) {
          customerName = customerData['name'] ?? 'Unknown Customer';
          customerImage = customerData['profileImage'] ?? customerImage;
        }

        print('Updating state with order data...');
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

          // Convert API items to OrderItem objects
          for (var item in items) {
            _orderItems.add(OrderItem(
              id: item['_id'] ?? '',
              name: item['product'] != null && item['product'] is Map
                  ? item['product']['name'] ?? 'Unknown Product'
                  : 'Unknown Product',
              description: item['notes'] ?? '',
              quantity:
                  (item['quantity'] is num) ? item['quantity'].toInt() : 1,
              price: (item['price'] is num) ? item['price'].toDouble() : 0.0,
              icon: _getIconForProduct(
                  item['product'] != null && item['product'] is Map
                      ? item['product']['name'] ?? 'Unknown Product'
                      : 'Unknown Product'),
              status: item['status'] ?? 'New',
            ));
          }

          _totalAmount = (orderData['totalAmount'] is num)
              ? orderData['totalAmount'].toDouble()
              : 0.0;
          _isLoading = false;
        });
        print('State updated successfully');

        // Handle empty items - attempt to fetch detailed data if needed
        if (_orderItems.isEmpty) {
          print('No items found, attempting to fetch detailed order items...');
          await _fetchDetailedOrderItems();
        }
      } else {
        print('Failed to fetch order details');
        if (!result['unauthorized']) {
          print('Error message: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(result['error'] ?? 'Failed to load order details'),
                backgroundColor: AppTheme.accentColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('=== Error in _fetchOrderDetails ===');
      print('Error details: $e');
      print('Stack trace: ${StackTrace.current}');
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
        print('Setting loading state to false');
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
            status: item['status'] ?? 'New',
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
              status: 'New',
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
              status: 'New',
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
            status: 'New',
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

    // Get the route from the AppBottomNav
    final String route = AppBottomNav.getRouteForIndex(index);
    print('Navigating to route: $route');

    // Navigate to the selected route and clear the navigation stack
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false,
        arguments: {'shouldRefresh': true});
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  String _getNextStatus() {
    switch (_status) {
      case 'New':
        return 'In Progress';
      case 'In Progress':
        // Check if all items are ready
        bool allItemsReady = true;
        for (var item in _orderItems) {
          if (item.status != 'Ready') {
            allItemsReady = false;
            break;
          }
        }
        return allItemsReady ? 'Ready' : 'Partially Ready';
      case 'Partially Ready':
        // Check if all items are ready
        bool allItemsReady = true;
        for (var item in _orderItems) {
          if (item.status != 'Ready') {
            allItemsReady = false;
            break;
          }
        }
        return allItemsReady ? 'Ready' : 'Partially Ready';
      case 'Ready':
        // Only allow completion after payment
        return 'Completed';
      default:
        return _status;
    }
  }

  Future<bool?> _showItemReadinessDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mark Items as Ready'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _orderItems.map((item) {
                    return CheckboxListTile(
                      title: Text(item.name),
                      subtitle: Text('Quantity: ${item.quantity}'),
                      value: item.status == 'Ready',
                      onChanged: (bool? value) {
                        setState(() {
                          // Create a new OrderItem with updated status
                          final updatedItem = OrderItem(
                            id: item.id,
                            name: item.name,
                            description: item.description,
                            quantity: item.quantity,
                            price: item.price,
                            icon: item.icon,
                            status: value == true ? 'Ready' : 'In Progress',
                          );
                          // Update the item in the list
                          final index = _orderItems.indexOf(item);
                          _orderItems[index] = updatedItem;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String newStatus, String itemId) async {
    if (_orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID is missing')),
      );
      return;
    }

    // Show readiness dialog when transitioning to Ready
    if (newStatus == 'Ready' && _status == 'In Progress') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Item Readiness'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _orderItems.map((item) {
              return CheckboxListTile(
                title: Text(item.name),
                value: item.status == 'Ready',
                onChanged: (bool? value) {
                  setState(() {
                    // Update the item's status in the list
                    final index = _orderItems.indexOf(item);
                    _orderItems[index] = OrderItem(
                      id: item.id,
                      name: item.name,
                      description: item.description,
                      quantity: item.quantity,
                      price: item.price,
                      icon: item.icon,
                      status: value == true ? 'Ready' : 'In Progress',
                    );
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    // Confirm payment when transitioning to Completed status
    if (newStatus == 'Completed') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text('Has the customer paid for this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the specific item's status first
      final result = await _apiService.updateOrderStatus(
        _orderId,
        itemId,
        newStatus,
      );

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Failed to update item status');
      }

      // Calculate new order status based on updated item statuses
      String newOrderStatus;
      bool allCompleted = true;
      bool allReady = true;
      bool hasReady = false;
      bool hasInProgress = false;

      // Update local state to reflect the new item status
      setState(() {
        final itemIndex = _orderItems.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          _orderItems[itemIndex] = OrderItem(
            id: _orderItems[itemIndex].id,
            name: _orderItems[itemIndex].name,
            description: _orderItems[itemIndex].description,
            quantity: _orderItems[itemIndex].quantity,
            price: _orderItems[itemIndex].price,
            icon: _orderItems[itemIndex].icon,
            status: newStatus,
          );
        }
      });

      // Check all items' statuses
      for (var item in _orderItems) {
        if (item.status != 'Completed') allCompleted = false;
        if (item.status != 'Ready') allReady = false;
        if (item.status == 'Ready' || item.status == 'Completed')
          hasReady = true;
        if (item.status == 'In Progress') hasInProgress = true;
      }

      // Determine the new order status
      if (allCompleted) {
        newOrderStatus = 'Completed';
      } else if (allReady) {
        newOrderStatus = 'Ready';
      } else if (hasReady) {
        newOrderStatus = 'Partially Ready';
      } else if (hasInProgress) {
        newOrderStatus = 'In Progress';
      } else {
        newOrderStatus = 'New';
      }

      // Update the order status with additional tags
      final orderUpdateResult = await _apiService.updateOrder(
        _orderId,
        {
          'status': newOrderStatus,
          'isPaid': newStatus == 'Completed',
          'tags': [
            if (_priority == 'High') 'Urgent',
            if (newStatus == 'Completed') 'Paid' else 'Unpaid',
          ],
        },
      );

      if (!orderUpdateResult['success']) {
        throw Exception(
            orderUpdateResult['error'] ?? 'Failed to update order status');
      }

      // Refresh order details to get the latest status
      await _fetchOrderDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                _updateOrderStatus('Completed', '');
              },
              child: const Text('Payment Received'),
            ),
          ],
        );
      },
    );
  }

  // Add a method to show item status selection dialog
  Future<void> _showItemStatusDialog(OrderItem item) async {
    final String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status for ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('New'),
              onTap: () => Navigator.pop(context, 'New'),
            ),
            ListTile(
              title: const Text('In Progress'),
              onTap: () => Navigator.pop(context, 'In Progress'),
            ),
            ListTile(
              title: const Text('Ready'),
              onTap: () => Navigator.pop(context, 'Ready'),
            ),
            ListTile(
              title: const Text('Completed'),
              onTap: () => Navigator.pop(context, 'Completed'),
            ),
          ],
        ),
      ),
    );

    if (newStatus != null) {
      await _updateOrderStatus(newStatus, item.id);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return AppTheme.statusInProgress;
      case 'in progress':
        return AppTheme.statusInProgress;
      case 'ready':
        return AppTheme.statusReady;
      case 'completed':
        return AppTheme.statusCompleted;
      case 'partially ready':
        return AppTheme.statusReady;
      default:
        return AppTheme.textSecondary;
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
                        (index) => _buildOrderItem(_orderItems[index]),
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

  Widget _buildOrderItem(OrderItem item) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTheme.headingSmall,
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTheme.bodyRegular,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Quantity: ${item.quantity} • ₹${item.price.toStringAsFixed(2)}',
                    style: AppTheme.bodyRegular,
                  ),
                ],
              ),
            ),
            // Right side - Status dropdown
            const SizedBox(width: AppTheme.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(item.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(item.status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: DropdownButton<String>(
                value: item.status,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _getStatusColor(item.status),
                ),
                underline: const SizedBox(),
                style: TextStyle(
                  color: _getStatusColor(item.status),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'New',
                    child: Text('New'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'In Progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Ready',
                    child: Text('Ready'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateOrderStatus(newValue, item.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
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
