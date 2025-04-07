import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import '../services/api_service.dart';
import 'dart:async';

class OrderStatus {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  OrderStatus({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class TrackOrder {
  final String id;
  final String customerName;
  final String customerImage;
  final String orderNumber;
  final String items;
  final String dueDate;
  final double price;
  final String status;

  TrackOrder({
    required this.id,
    required this.customerName,
    required this.customerImage,
    required this.orderNumber,
    required this.items,
    required this.dueDate,
    required this.price,
    required this.status,
  });
}

class TrackScreen extends StatefulWidget {
  const TrackScreen({Key? key}) : super(key: key);

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> with WidgetsBindingObserver {
  // Initialize current nav index to 2 (Track)
  int _currentNavIndex = 2;

  final List<OrderStatus> _filterStatuses = [
    OrderStatus(
      label: 'Ready',
      backgroundColor: const Color(0x333B82F6),
      textColor: const Color(0xFF3B82F6),
    ),
    OrderStatus(
      label: 'In Progress',
      backgroundColor: const Color(0x3310B981),
      textColor: const Color(0xFF10B981),
    ),
    OrderStatus(
      label: 'Urgent',
      backgroundColor: const Color(0x33E5E7EB),
      textColor: const Color(0xFFDC2626),
    ),
    OrderStatus(
      label: 'New',
      backgroundColor: const Color(0x33DAE8FF),
      textColor: const Color(0xFFDAE8FF),
    ),
  ];

  // Replace mock orders with real data
  final List<TrackOrder> _orders = [];

  String? _selectedStatusFilter;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreOrders = true;
  bool _isInitialLoading = true;
  int _currentPage = 1;
  final ApiService _apiService = ApiService();
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    _fetchOrders();
    _lastRefreshTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if it's been more than 30 seconds since the last refresh
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!).inSeconds > 30) {
        print('Track screen resumed, refreshing orders');
        _refreshOrders();
      }
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      if (_currentPage == 1) {
        _isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      // Call your API service to get orders
      final response = await _apiService.getOrders(page: _currentPage);

      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _orders.clear();
        }

        // Map API response to TrackOrder objects
        final List<dynamic> ordersData = response['orders'] ?? [];

        for (var orderData in ordersData) {
          final items = orderData['items'] ?? [];
          final customer = orderData['customer'] ?? {};

          _orders.add(TrackOrder(
            id: orderData['_id'] ?? '',
            customerName: customer['name'] ?? 'Unknown Customer',
            customerImage: customer['image'] ??
                'https://randomuser.me/api/portraits/men/1.jpg',
            orderNumber: '#${orderData['orderNumber'] ?? ''}',
            items: '${items.length} ${items.length == 1 ? "Item" : "Items"}',
            dueDate: orderData['dueDate'] ?? 'No due date',
            price: double.tryParse('${orderData['totalAmount']}') ?? 0.0,
            status: orderData['status'] ?? 'New',
          ));
        }

        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMoreOrders = ordersData.length > 0;
        _currentPage++;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      if (!mounted) return;

      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    print('Refreshing orders in Track screen...');
    _lastRefreshTime = DateTime.now();
    _currentPage = 1;
    _hasMoreOrders = true;
    await _fetchOrders();
  }

  void _loadMoreOrders() {
    if (!_isLoadingMore && _hasMoreOrders) {
      _fetchOrders();
    }
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in track.dart: $index');

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

  void _filterByStatus(String? status) {
    setState(() {
      if (_selectedStatusFilter == status) {
        // If already selected, clear the filter
        _selectedStatusFilter = null;
      } else {
        _selectedStatusFilter = status;
      }
    });
  }

  List<TrackOrder> get _filteredOrders {
    if (_selectedStatusFilter == null) {
      return _orders;
    }
    return _orders
        .where((order) => order.status == _selectedStatusFilter)
        .toList();
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notification functionality
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _hasMoreOrders &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshOrders,
          child: _buildContent(),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // User profile header
        UserProfileHeader(
          name: 'James',
          role: 'Master Tailor',
          profileImageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
          onProfileTap: _navigateToProfile,
          onNotificationTap: _showNotifications,
        ),

        // Title and filters
        Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Order Tracking',
                style: AppTheme.headingLarge,
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Status filters
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterStatuses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final status = _filterStatuses[index];
                    final isSelected = _selectedStatusFilter == status.label;

                    return FilterChip(
                      selected: isSelected,
                      backgroundColor: status.backgroundColor,
                      selectedColor: status.backgroundColor.withOpacity(0.8),
                      side: status.label == 'Urgent'
                          ? const BorderSide(color: Color(0xFFDC2626))
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      label: Text(
                        status.label,
                        style: TextStyle(
                          color: status.textColor,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onSelected: (selected) {
                        _filterByStatus(status.label);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Order list with infinite scrolling
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
            itemCount: _filteredOrders.length +
                (_hasMoreOrders && _selectedStatusFilter == null ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _filteredOrders.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.paddingMedium),
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }

              return _buildOrderCard(_filteredOrders[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(TrackOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/order_detail',
              arguments: {'id': order.id},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer image
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(order.customerImage),
                    ),
                    const SizedBox(width: AppTheme.paddingSmall),

                    // Customer name and order number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: AppTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    _buildStatusBadge(order.status),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingSmall),

                Text(
                  order.orderNumber,
                  style: AppTheme.bodySmall,
                ),

                const SizedBox(height: AppTheme.paddingSmall),

                // Order details
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${order.items} • Due ${order.dueDate}',
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Price on a new line
                Text(
                  '₹${order.price.toStringAsFixed(2)}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'In Progress':
        backgroundColor = const Color(0x3310B981);
        textColor = const Color(0xFF10B981);
        break;
      case 'Ready':
        backgroundColor = const Color(0x333B82F6);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'Urgent':
        backgroundColor = const Color(0x33E5E7EB);
        textColor = const Color(0xFFDC2626);
        break;
      case 'New':
        backgroundColor = const Color(0x33DAE8FF);
        textColor = const Color(0xFFDAE8FF);
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
        border: status == 'Urgent'
            ? Border.all(color: const Color(0xFFDC2626))
            : null,
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
