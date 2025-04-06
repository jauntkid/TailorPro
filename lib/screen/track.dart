import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';

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

class _TrackScreenState extends State<TrackScreen> {
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

  // Initial list of orders - showing 5 at first
  final List<TrackOrder> _orders = List.generate(
      5,
      (index) => TrackOrder(
            id: 'order_${index + 1}',
            customerName: 'Customer ${index + 1}',
            customerImage:
                'https://randomuser.me/api/portraits/${index % 2 == 0 ? "men" : "women"}/${index + 1}.jpg',
            orderNumber: '#ORD-2025${100 + index}',
            items:
                '${(index % 3) + 1} ${(index % 3) + 1 == 1 ? "Item" : "Items"}',
            dueDate: 'Jan ${15 + (index % 15)}',
            price: 149.00 + (index * 50.0),
            status: index % 4 == 0
                ? 'Ready'
                : (index % 4 == 1
                    ? 'In Progress'
                    : (index % 4 == 2 ? 'Urgent' : 'New')),
          ));

  String? _selectedStatusFilter;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreOrders = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _hasMoreOrders &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadMoreOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Add 5 more mock orders
    setState(() {
      final int currentLength = _orders.length;
      _orders.addAll(List.generate(
          5,
          (index) => TrackOrder(
                id: 'order_${currentLength + index + 1}',
                customerName: 'Customer ${currentLength + index + 1}',
                customerImage:
                    'https://randomuser.me/api/portraits/${(currentLength + index) % 2 == 0 ? "men" : "women"}/${(currentLength + index) % 10 + 1}.jpg',
                orderNumber: '#ORD-2025${100 + currentLength + index}',
                items:
                    '${((currentLength + index) % 3) + 1} ${((currentLength + index) % 3) + 1 == 1 ? "Item" : "Items"}',
                dueDate: 'Jan ${15 + ((currentLength + index) % 15)}',
                price: 149.00 + ((currentLength + index) * 50.0),
                status: (currentLength + index) % 4 == 0
                    ? 'Ready'
                    : ((currentLength + index) % 4 == 1
                        ? 'In Progress'
                        : ((currentLength + index) % 4 == 2
                            ? 'Urgent'
                            : 'New')),
              )));

      _isLoadingMore = false;

      // Stop loading more after reaching a certain number
      if (_orders.length > 50) {
        _hasMoreOrders = false;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
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
                        final isSelected =
                            _selectedStatusFilter == status.label;

                        return FilterChip(
                          selected: isSelected,
                          backgroundColor: status.backgroundColor,
                          selectedColor:
                              status.backgroundColor.withOpacity(0.8),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium),
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
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
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
