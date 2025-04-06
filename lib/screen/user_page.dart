import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserOrder {
  final String orderNumber;
  final String items;
  final String dueDate;
  final double price;
  final String status;

  UserOrder({
    required this.orderNumber,
    required this.items,
    required this.dueDate,
    required this.price,
    required this.status,
  });
}

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _currentNavIndex = 0;

  // Replace mock user data with API data
  Map<String, dynamic> _userData = {
    'name': 'Loading...',
    'phoneNumber': '',
    'address': '',
    'referral': '',
    'notes': '',
    'profileImage': 'https://randomuser.me/api/portraits/men/1.jpg',
  };

  // API service for fetching data
  final ApiService _apiService = ApiService();
  bool _isLoadingProfile = true;

  // Mock order data
  final List<UserOrder> _orders = List.generate(
      20,
      (index) => UserOrder(
            orderNumber: '#ORD-2025${100 + index}',
            items:
                '${(index % 3) + 1} ${(index % 3) + 1 == 1 ? "Item" : "Items"}',
            dueDate: 'Jan ${15 + (index % 15)}',
            price: 149.00 + (index * 50.0),
            status: index % 3 == 0
                ? 'Ready'
                : (index % 3 == 1 ? 'In Progress' : 'Urgent'),
          ));

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreOrders = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchUserProfile();
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
          (index) => UserOrder(
                orderNumber: '#ORD-2025${100 + currentLength + index}',
                items:
                    '${(index % 3) + 1} ${(index % 3) + 1 == 1 ? "Item" : "Items"}',
                dueDate: 'Jan ${15 + (index % 15)}',
                price: 149.00 + ((currentLength + index) * 50.0),
                status: index % 3 == 0
                    ? 'Ready'
                    : (index % 3 == 1 ? 'In Progress' : 'Urgent'),
              )));

      _isLoadingMore = false;

      // Stop loading more after reaching a certain number
      if (_orders.length > 50) {
        _hasMoreOrders = false;
      }
    });
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in user_page.dart: $index');

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

  void _navigateBack() {
    Navigator.pop(context);
  }

  void _editCustomer() {
    // Navigate to edit customer screen
    Navigator.pushNamed(context, '/new_customer');
  }

  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Customer', style: AppTheme.headingMedium),
        content: const Text(
            'Are you sure you want to delete this customer? This action cannot be undone.',
            style: AppTheme.bodyRegular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer deleted'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetail() {
    Navigator.pushNamed(context, '/order_detail');
  }

  // Fetch user profile from API
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // First try to get user from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userData != null) {
        setState(() {
          _userData = {
            'name': authProvider.userData!['name'] ?? 'Unknown User',
            'phoneNumber': authProvider.userData!['phone'] ?? '',
            'address': authProvider.userData!['address'] ?? '',
            'referral': authProvider.userData!['referral'] ?? '',
            'notes': authProvider.userData!['notes'] ?? '',
            'profileImage': authProvider.userData!['profileImage'] ??
                'https://randomuser.me/api/portraits/men/1.jpg',
          };
          _isLoadingProfile = false;
        });
        return;
      }

      // If not available in provider, fetch from API
      final result = await _apiService.getCurrentUser();
      print('User profile API response: $result');

      if (result['success'] && result['data'] != null) {
        final userData = result['data'];
        setState(() {
          _userData = {
            'name': userData['name'] ?? 'Unknown User',
            'phoneNumber': userData['phone'] ?? '',
            'address': userData['address'] ?? '',
            'referral': userData['referral'] ?? '',
            'notes': userData['notes'] ?? '',
            'profileImage': userData['profileImage'] ??
                'https://randomuser.me/api/portraits/men/1.jpg',
          };
        });
      } else {
        print('Failed to load user profile: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile. Using cached data.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Customer Profile', style: AppTheme.headingLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _navigateBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textPrimary),
            onPressed: _editCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.accentColor),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: Column(
        children: [
          // User profile card
          _buildUserProfileCard(),

          // Order history
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order History',
                  style: AppTheme.headingMedium,
                ),
                Text(
                  '${_orders.length} orders',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Order list with infinite scrolling
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              itemCount: _orders.length + (_hasMoreOrders ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _orders.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingMedium),
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    ),
                  );
                }

                return _buildOrderCard(_orders[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildUserProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image and name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_userData['profileImage']),
                    ),
                    const SizedBox(width: AppTheme.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData['name'],
                            style: AppTheme.headingMedium,
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(Icons.phone, _userData['phoneNumber']),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingMedium),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: AppTheme.paddingMedium),

                // Other details
                _buildInfoRow(Icons.location_on, _userData['address']),
                const SizedBox(height: AppTheme.paddingSmall),

                _buildInfoRow(
                    Icons.people, 'Referral: ${_userData['referral']}'),
                const SizedBox(height: AppTheme.paddingSmall),

                _buildInfoRow(Icons.note, _userData['notes']),
              ],
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyRegular,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(UserOrder order) {
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
          onTap: _navigateToOrderDetail,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: AppTheme.bodyLarge,
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingSmall),

                // Order details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items} • Due ${order.dueDate}',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '₹${order.price.toStringAsFixed(2)}',
                      style: AppTheme.bodyLarge,
                    ),
                  ],
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
