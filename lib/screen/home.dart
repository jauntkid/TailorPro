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
import 'dart:async';
import '../models/customer.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Initialize the current nav index to 0 (Home)
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<HomeOrder> _orders = [];
  bool _isOrdersLoading = false;
  bool _hasMoreOrders = true;
  int _currentPage = 1; // For pagination (if supported by your API)

  final ScrollController _scrollController = ScrollController();
  DateTime? _lastRefreshTime;
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchOrders(); // Fetch initial orders from API
    _scrollController.addListener(_scrollListener);
    _lastRefreshTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if it's been more than 30 seconds since the last refresh
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!).inSeconds > 30) {
        print('App resumed, refreshing orders');
        _refreshOrders();
      }
    }
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
    if (_isOrdersLoading) return;

    setState(() {
      _isOrdersLoading = true;
    });

    try {
      final result = await _apiService.getOrders(
        page: _currentPage,
        limit: 5,
        search: _searchController.text,
        context: context,
      );

      if (result['success']) {
        final List<dynamic> orders = result['data']['data'] ?? [];
        final int totalOrders = result['data']['total'] ?? 0;

        setState(() {
          _orders = orders.map((order) {
            // Format order items for display
            String itemsText = '';
            if (order['items'] != null && order['items'] is List) {
              List<String> itemNames = [];
              for (var item in order['items']) {
                String name = 'Unknown item';
                if (item['product'] != null) {
                  if (item['product'] is Map) {
                    name = item['product']['name'] ?? name;
                  } else if (item['product'] is String) {
                    name = 'Item';
                  }
                }
                if (item['quantity'] != null) {
                  name = '${item['quantity']}x $name';
                }
                itemNames.add(name);
              }
              if (itemNames.length > 1) {
                itemsText = '${itemNames[0]} +${itemNames.length - 1} more';
              } else if (itemNames.length == 1) {
                itemsText = itemNames[0];
              }
            }

            // Format date
            String dueDate = '';
            if (order['dueDate'] != null) {
              try {
                DateTime dateTime = DateTime.parse(order['dueDate']);
                dueDate = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
              } catch (e) {
                dueDate = 'Invalid date';
              }
            }

            return HomeOrder(
              id: order['_id'] ?? '',
              customerName:
                  order['customer'] != null && order['customer'] is Map
                      ? order['customer']['name'] ?? 'Unknown Customer'
                      : 'Unknown Customer',
              orderNumber: order['orderNumber'] ?? '',
              items: itemsText,
              dueDate: dueDate,
              price: (order['totalAmount'] is num)
                  ? order['totalAmount'].toDouble()
                  : 0.0,
              status: order['status'] ?? 'Unknown',
            );
          }).toList();
          _hasMoreOrders = _orders.length < totalOrders;
          _isOrdersLoading = false;
        });
      } else {
        setState(() {
          _isOrdersLoading = false;
        });

        if (!result['unauthorized']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to fetch orders'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isOrdersLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
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
      final List<dynamic> orders = result['data']['data'] ?? [];
      final int totalOrders = result['data']['total'] ?? 0;

      if (orders.isEmpty) {
        setState(() {
          _hasMoreOrders = false;
        });
      } else {
        List<HomeOrder> parsedOrders = orders.map((order) {
          // Format order items for display
          String itemsText = '';
          if (order['items'] != null && order['items'] is List) {
            List<String> itemNames = [];
            for (var item in order['items']) {
              String name = 'Unknown item';
              if (item['product'] != null) {
                if (item['product'] is Map) {
                  name = item['product']['name'] ?? name;
                } else if (item['product'] is String) {
                  name = 'Item';
                }
              }
              if (item['quantity'] != null) {
                name = '${item['quantity']}x $name';
              }
              itemNames.add(name);
            }
            if (itemNames.length > 1) {
              itemsText = '${itemNames[0]} +${itemNames.length - 1} more';
            } else if (itemNames.length == 1) {
              itemsText = itemNames[0];
            }
          }

          // Format date
          String dueDate = '';
          if (order['dueDate'] != null) {
            try {
              DateTime dateTime = DateTime.parse(order['dueDate']);
              dueDate = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
            } catch (e) {
              dueDate = 'Invalid date';
            }
          }

          return HomeOrder(
            id: order['_id'] ?? '',
            customerName: order['customer'] != null && order['customer'] is Map
                ? order['customer']['name'] ?? 'Unknown Customer'
                : 'Unknown Customer',
            orderNumber: order['orderNumber'] ?? '',
            items: itemsText,
            dueDate: dueDate,
            price: (order['totalAmount'] is num)
                ? order['totalAmount'].toDouble()
                : 0.0,
            status: order['status'] ?? 'Unknown',
          );
        }).toList();

        setState(() {
          _orders.addAll(parsedOrders);
          _hasMoreOrders = _orders.length < totalOrders;
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // Search both orders and customers
      final ordersResult = await _apiService.getOrders(
        search: query,
        page: 1,
        limit: 5,
      );

      final customersResult = await _apiService.getCustomers(
        search: query,
        page: 1,
        limit: 5,
      );

      List<dynamic> searchResults = [];

      if (ordersResult['success'] == true) {
        List<dynamic> ordersJson = [];
        if (ordersResult['data'] is List) {
          ordersJson = ordersResult['data'];
        } else if (ordersResult['data'] is Map &&
            ordersResult['data'].containsKey('data')) {
          ordersJson = ordersResult['data']['data'];
        }
        searchResults.addAll(
            ordersJson.map((order) => {'type': 'order', 'data': order}));
      }

      if (customersResult['success'] == true) {
        List<dynamic> customersJson = [];
        if (customersResult['data'] is List) {
          customersJson = customersResult['data'];
        } else if (customersResult['data'] is Map &&
            customersResult['data'].containsKey('data')) {
          customersJson = customersResult['data']['data'];
        }
        searchResults.addAll(customersJson
            .map((customer) => {'type': 'customer', 'data': customer}));
      }

      setState(() {
        _searchResults = searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _handleSearchResultTap(Map<String, dynamic> result) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    if (result['type'] == 'order') {
      _navigateToOrderDetail(result['data']['_id']);
    } else if (result['type'] == 'customer') {
      Navigator.pushNamed(
        context,
        '/customer_detail',
        arguments: {'id': result['data']['_id']},
      );
    }
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in home.dart: $index');

    // Don't navigate if already on the selected page
    if (index == _currentNavIndex) {
      print('Already on this page, not navigating');
      return;
    }

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
    Navigator.pushNamed(context, '/new_order').then((_) {
      // Refresh orders when returning from new order screen
      _refreshOrders();
    });
  }

  void _navigateToOrderDetail(String orderId) {
    Navigator.pushNamed(
      context,
      '/order_detail',
      arguments: {'id': orderId},
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

  // Method to manually refresh orders
  Future<void> _refreshOrders() async {
    print('Refreshing orders...');
    _lastRefreshTime = DateTime.now();
    _currentPage = 1;
    _hasMoreOrders = true;
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Get the logged-in user's data from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                  onSearch: _onSearchChanged,
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
                                    color:
                                        AppTheme.textSecondary.withOpacity(0.5),
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
                              padding:
                                  const EdgeInsets.all(AppTheme.paddingMedium),
                              itemCount:
                                  _orders.length + (_hasMoreOrders ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _orders.length) {
                                  return _hasMoreOrders
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }

                                final order = _orders[index];
                                return OrderCard(
                                  customerName: order.customerName,
                                  orderNumber: order.orderNumber,
                                  items: order.items,
                                  dueDate: order.dueDate,
                                  price: order.price,
                                  status: order.status,
                                  onTap: () => _navigateToOrderDetail(order.id),
                                  currencySymbol: '₹',
                                );
                              },
                            ),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Card(
                  margin: EdgeInsets.all(8),
                  color: AppTheme.cardBackground,
                  child: Column(
                    children: _searchResults.map((result) {
                      final data = result['data'];
                      final isOrder = result['type'] == 'order';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Icon(
                            isOrder ? Icons.shopping_bag : Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          isOrder ? data['orderNumber'] : data['name'],
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          isOrder ? 'Order' : data['phone'] ?? 'No phone',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                        onTap: () => _handleSearchResultTap(result),
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (_isSearching)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Card(
                  margin: EdgeInsets.all(8),
                  color: AppTheme.cardBackground,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
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
}
