import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/action_card.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/order_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/user_profile_header.dart';
import '../providers/auth_provider.dart';

class HomeOrder {
  final String id;
  final String customerName;
  final String orderNumber;
  final String items;
  final String dueDate;
  final double price;
  final String status;

  HomeOrder({
    required this.id,
    required this.customerName,
    required this.orderNumber,
    required this.items,
    required this.dueDate,
    required this.price,
    required this.status,
  });

  // Factory constructor to create a HomeOrder from JSON data
  factory HomeOrder.fromJson(Map<String, dynamic> json) {
    return HomeOrder(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? 'Unknown Customer',
      orderNumber: json['orderNumber'] ?? '',
      items: json['items'] ?? '',
      dueDate: json['dueDate'] ?? '',
      price: (json['price'] is num) ? json['price'].toDouble() : 0.0,
      status: json['status'] ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialize the current nav index to 0 (Home)
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<HomeOrder> _orders = [];
  bool _isOrdersLoading = false;
  bool _hasMoreOrders = true;
  int _currentPage = 1; // For pagination (if supported by your API)

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrders(); // Fetch initial orders from API
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isOrdersLoading &&
        _hasMoreOrders &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      _isOrdersLoading = true;
    });

    try {
      // Fetch orders with page=1 and limit=5
      final result = await _apiService.getOrders(page: _currentPage, limit: 5);

      if (!mounted) return;

      if (result['success'] == true) {
        List<dynamic> ordersJson = [];

        // Handle different API response structures
        if (result['data'] is List) {
          ordersJson = result['data'];
        } else if (result['data'] is Map &&
            result['data'].containsKey('data')) {
          ordersJson = result['data']['data'];
        }

        List<HomeOrder> parsedOrders = [];
        for (var json in ordersJson) {
          try {
            // Convert JSON to more structured data
            Map<String, dynamic> orderData = {
              'id': json['_id'] ?? '',
              'customerName': json['customer'] is Map
                  ? json['customer']['name']
                  : 'Unknown Customer',
              'orderNumber': json['orderNumber'] ?? 'No number',
              'items': _formatOrderItems(json['items']),
              'dueDate': _formatDate(json['dueDate']),
              'price': json['totalAmount'] is num
                  ? json['totalAmount'].toDouble()
                  : 0.0,
              'status': json['status'] ?? 'Unknown',
            };
            parsedOrders.add(HomeOrder.fromJson(orderData));
          } catch (e) {
            print('Error parsing order: $e');
          }
        }

        if (mounted) {
          setState(() {
            _orders = parsedOrders;
            _isOrdersLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isOrdersLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to load orders')),
          );
        }
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (mounted) {
        setState(() {
          _isOrdersLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching orders: $e')),
        );
      }
    }
  }

  // Format order items for display
  String _formatOrderItems(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 'No items';

    List<String> itemNames = [];
    for (var item in items) {
      String name = 'Unknown item';
      if (item is Map) {
        if (item['product'] is Map && item['product'].containsKey('name')) {
          name = item['product']['name'];
        } else if (item['product'] is String) {
          name = 'Item';
        }

        // Add quantity if available
        if (item.containsKey('quantity') && item['quantity'] != null) {
          name = '${item['quantity']}x $name';
        }
      }
      itemNames.add(name);
    }

    // Return first item + count of additional items
    if (itemNames.length > 1) {
      return '${itemNames[0]} +${itemNames.length - 1} more';
    } else if (itemNames.length == 1) {
      return itemNames[0];
    } else {
      return 'No items';
    }
  }

  // Format date for display
  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'No date';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'Invalid date';
      }

      // Format as MM/DD/YYYY
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _loadMoreOrders() async {
    if (!mounted) return;
    setState(() {
      _isOrdersLoading = true;
    });
    _currentPage++;
    final result = await _apiService.getOrders(page: _currentPage, limit: 5);
    if (result['success']) {
      List<dynamic> ordersJson = [];

      // Handle different API response structures
      if (result['data'] is List) {
        ordersJson = result['data'];
      } else if (result['data'] is Map && result['data'].containsKey('data')) {
        ordersJson = result['data']['data'];
      }

      if (ordersJson.isEmpty) {
        setState(() {
          _hasMoreOrders = false;
        });
      } else {
        List<HomeOrder> parsedOrders = [];
        for (var json in ordersJson) {
          try {
            // Convert JSON to more structured data
            Map<String, dynamic> orderData = {
              'id': json['_id'] ?? '',
              'customerName': json['customer'] is Map
                  ? json['customer']['name']
                  : 'Unknown Customer',
              'orderNumber': json['orderNumber'] ?? 'No number',
              'items': _formatOrderItems(json['items']),
              'dueDate': _formatDate(json['dueDate']),
              'price': json['totalAmount'] is num
                  ? json['totalAmount'].toDouble()
                  : 0.0,
              'status': json['status'] ?? 'Unknown',
            };
            parsedOrders.add(HomeOrder.fromJson(orderData));
          } catch (e) {
            print('Error parsing order: $e');
          }
        }

        setState(() {
          _orders.addAll(parsedOrders);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['error'] ?? 'Failed to load more orders')),
      );
    }
    setState(() {
      _isOrdersLoading = false;
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(width: 20),
              Text("Searching...", style: AppTheme.bodyRegular),
            ],
          ),
        );
      },
    );

    try {
      // Search for orders
      final orderResults = await _apiService.getOrders(search: query, limit: 5);

      // Search for customers
      final customerResults =
          await _apiService.getCustomers(search: query, limit: 5);

      // Dismiss loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Handle no results or error cases
      bool hasOrderResults = orderResults['success'] == true &&
          orderResults['data'] != null &&
          (orderResults['data'] is List
              ? orderResults['data'].isNotEmpty
              : (orderResults['data'] is Map &&
                      orderResults['data']['data'] != null
                  ? orderResults['data']['data'].isNotEmpty
                  : false));

      bool hasCustomerResults = customerResults['success'] == true &&
          customerResults['data'] != null &&
          (customerResults['data'] is List
              ? customerResults['data'].isNotEmpty
              : (customerResults['data'] is Map &&
                      customerResults['data']['data'] != null
                  ? customerResults['data']['data'].isNotEmpty
                  : false));

      // If no results found
      if (!hasOrderResults && !hasCustomerResults) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found for "$query"')),
        );
        return;
      }

      // Get the data in the correct format
      List<dynamic> orders = [];
      if (hasOrderResults) {
        if (orderResults['data'] is List) {
          orders = orderResults['data'];
        } else if (orderResults['data'] is Map &&
            orderResults['data']['data'] != null) {
          orders = orderResults['data']['data'];
        }
      }

      List<dynamic> customers = [];
      if (hasCustomerResults) {
        if (customerResults['data'] is List) {
          customers = customerResults['data'];
        } else if (customerResults['data'] is Map &&
            customerResults['data']['data'] != null) {
          customers = customerResults['data']['data'];
        }
      }

      // Show results in a bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text('Search Results',
                        style: AppTheme.headingMedium),
                  ),
                  Divider(color: AppTheme.textSecondary.withOpacity(0.3)),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      children: [
                        // Orders section
                        if (orders.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Orders',
                                style: AppTheme.bodyLarge
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ),
                          ...List.generate(orders.length, (index) {
                            final order = orders[index];
                            final customerName = order['customer'] != null &&
                                    order['customer'] is Map
                                ? order['customer']['name'] ??
                                    'Unknown customer'
                                : 'Unknown customer';
                            return ListTile(
                              title: Text(
                                  order['orderNumber'] ?? 'No order number',
                                  style: AppTheme.bodyRegular),
                              subtitle: Text(
                                '$customerName - ${order['status'] ?? 'Unknown status'}',
                                style: AppTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to order detail page with order id
                                Navigator.pushNamed(context, '/order_detail',
                                    arguments: {'id': order['_id']});
                              },
                            );
                          }),
                        ],
                        // Customers section
                        if (customers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Customers',
                                style: AppTheme.bodyLarge
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ),
                          ...List.generate(customers.length, (index) {
                            final customer = customers[index];
                            return ListTile(
                              title: Text(customer['name'] ?? 'No name',
                                  style: AppTheme.bodyRegular),
                              subtitle: Text(
                                customer['phone'] ?? 'No phone',
                                style: AppTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to user detail page with customer id
                                Navigator.pushNamed(context, '/user_page',
                                    arguments: {'id': customer['_id']});
                              },
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  void _handleNavTap(int index) {
    // Print debug info
    print('Navigation tapped: $index');

    if (index == _currentNavIndex) {
      print('Already on this page, not navigating');
      return; // Don't navigate if already on the page
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

  void _navigateToNewCustomer() {
    Navigator.pushNamed(context, '/new_customer');
  }

  void _navigateToNewOrder() {
    Navigator.pushNamed(context, '/new_order');
  }

  void _navigateToOrderDetail(HomeOrder order) {
    print('Navigating to order detail with ID: ${order.id}');
    Navigator.pushNamed(
      context,
      '/order_detail',
      arguments: {'id': order.id},
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notifications
  }

  void _viewAllOrders() {
    Navigator.pushNamed(context, '/track');
  }

  // Add debug method to create a test order
  Future<void> _createTestOrder() async {
    setState(() {
      _isOrdersLoading = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating test order...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create test order
      final result = await _apiService.createTestOrder();

      if (result['success'] && result['data'] != null) {
        final orderId = result['data']['_id'];

        // Navigate to the order detail page
        Navigator.pushNamed(
          context,
          '/order_detail',
          arguments: {'id': orderId},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test order created!'),
            backgroundColor: AppTheme.statusInProgress,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test order: ${result['error']}'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      print('Error creating test order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isOrdersLoading = false;
      });

      // Refresh orders list
      _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the logged-in user's data from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with user profile information fetched from the API
            UserProfileHeader(
              name: userData['name'] ?? 'Tailor User',
              role: userData['role'] ?? 'User',
              profileImageUrl: userData['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg',
              onProfileTap: _navigateToProfile,
              onNotificationTap: _showNotifications,
            ),
            // Search Bar
            CustomSearchBar(
              hintText: 'Search orders or customers',
              onSearch: _handleSearch,
              controller: _searchController,
            ),
            // Action Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingLarge,
              ),
              child: Row(
                children: [
                  ActionCard(
                    title: 'New User',
                    subtitle: 'Add customer',
                    backgroundColor: AppTheme.primary,
                    icon: Icons.person_add,
                    onTap: _navigateToNewCustomer,
                  ),
                  const SizedBox(width: AppTheme.paddingMedium),
                  ActionCard(
                    title: 'New Order',
                    subtitle: 'Create order',
                    backgroundColor: AppTheme.secondary,
                    icon: Icons.add_shopping_cart,
                    onTap: _navigateToNewOrder,
                  ),
                ],
              ),
            ),
            // Recent Orders Section Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: AppTheme.headingLarge,
                  ),
                  GestureDetector(
                    onTap: _viewAllOrders,
                    child: const Text(
                      'See All',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            // Orders list with infinite scrolling
            Expanded(
              child: _isOrdersLoading && _orders.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    )
                  : _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent orders',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _navigateToNewOrder,
                                child: const Text(
                                  'Create a new order',
                                  style: TextStyle(color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          itemCount: _orders.length + (_hasMoreOrders ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _orders.length) {
                              return const Center(
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(AppTheme.paddingMedium),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            }
                            final order = _orders[index];
                            return OrderCard(
                              customerName: order.customerName,
                              orderNumber: order.orderNumber,
                              items: order.items,
                              dueDate: order.dueDate,
                              price: order.price,
                              status: order.status,
                              onTap: () => _navigateToOrderDetail(order),
                              currencySymbol: '₹',
                            );
                          },
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
}
