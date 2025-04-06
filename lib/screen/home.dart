import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/action_card.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/order_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/user_profile_header.dart';

class HomeOrder {
  final String customerName;
  final String orderNumber;
  final String items;
  final String dueDate;
  final double price;
  final String status;

  HomeOrder({
    required this.customerName,
    required this.orderNumber,
    required this.items,
    required this.dueDate,
    required this.price,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Initial list of orders - showing 5 at first
  final List<HomeOrder> _orders = List.generate(
      5,
      (index) => HomeOrder(
            customerName: 'Customer ${index + 1}',
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
    _searchController.dispose();
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
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    // Add 5 more mock orders
    setState(() {
      final int currentLength = _orders.length;
      _orders.addAll(List.generate(
          5,
          (index) => HomeOrder(
                customerName: 'Customer ${currentLength + index + 1}',
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

  void _handleSearch(String query) {
    // Implement search functionality
  }

  void _handleNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _navigateToNewCustomer() {
    Navigator.pushNamed(context, '/new_customer');
  }

  void _navigateToNewOrder() {
    Navigator.pushNamed(context, '/new_order');
  }

  void _navigateToOrderDetail() {
    Navigator.pushNamed(context, '/order_detail');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with profile
            UserProfileHeader(
              name: 'James',
              role: 'Master Tailor',
              profileImageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
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
              padding: EdgeInsets.symmetric(
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
                  SizedBox(width: AppTheme.paddingMedium),
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
              padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: AppTheme.headingLarge,
                  ),
                  GestureDetector(
                    onTap: _viewAllOrders,
                    child: Text(
                      'See All',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            // Order list with infinite scrolling
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _orders.length + (_hasMoreOrders ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _orders.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.paddingMedium),
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
                    onTap: _navigateToOrderDetail,
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
