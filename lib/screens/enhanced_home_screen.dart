import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../services/enhanced_search_service.dart';
import '../services/database_seeding_service.dart';
import 'package:siri/models/enhanced_order.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import '../config/theme.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final EnhancedSearchService _searchService = EnhancedSearchService();
  final DatabaseSeedingService _seedingService = DatabaseSeedingService();

  List<SearchResult> _searchResults = [];
  List<Order> _recentOrders = [];
  bool _isSearching = false;
  bool _isLoadingOrders = false;
  bool _isDatabaseSeeded = false;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    final authProvider =
        Provider.of<FirebaseAuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null) {
      try {
        // Seed database with sample data
        if (!_isDatabaseSeeded) {
          await _seedingService.seedUserDatabase(userId);
          setState(() {
            _isDatabaseSeeded = true;
          });
        }

        // Load recent orders
        await _loadRecentOrders(userId);
      } catch (e) {
        debugPrint('Error initializing user data: $e');
      }
    }
  }

  Future<void> _loadRecentOrders(String userId) async {
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      // Get recent orders from search service
      final orders = await _searchService.searchOrdersOnly(userId, '');
      setState(() {
        _recentOrders = orders.take(10).toList();
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
      });
      debugPrint('Error loading recent orders: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    final authProvider =
        Provider.of<FirebaseAuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    try {
      final results = await _searchService.searchAll(userId, query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      debugPrint('Search error: $e');
    }
  }

  void _handleSearchResultTap(SearchResult result) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    switch (result.type) {
      case 'customer':
        Navigator.pushNamed(
          context,
          '/customer-detail',
          arguments: result.id,
        );
        break;
      case 'order':
        Navigator.pushNamed(
          context,
          '/order-detail',
          arguments: result.id,
        );
        break;
      case 'product':
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: result.id,
        );
        break;
    }
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    final route = AppBottomNav.getRouteForIndex(index);
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
  }

  void _navigateToNewCustomer() {
    Navigator.pushNamed(context, '/new-customer');
  }

  void _navigateToNewOrder() {
    Navigator.pushNamed(context, '/new-order');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // User Profile Header
                UserProfileHeader(
                  name: userData['name'] ?? 'Store User',
                  role: userData['role'] ?? 'Manager',
                  profileImageUrl: userData['profileImage'] ??
                      'https://randomuser.me/api/portraits/men/32.jpg',
                  onProfileTap: _navigateToProfile,
                  onNotificationTap: () {
                    // Show notifications
                  },
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.all(AppTheme.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodyRegular,
                    decoration: InputDecoration(
                      hintText: 'Search customers, orders, or products...',
                      hintStyle: AppTheme.bodyRegular.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                // Quick Actions
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          title: 'New Customer',
                          subtitle: 'Add customer details',
                          icon: Icons.person_add,
                          color: AppTheme.primary,
                          onTap: _navigateToNewCustomer,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingMedium),
                      Expanded(
                        child: _buildQuickActionCard(
                          title: 'New Order',
                          subtitle: 'Create new order',
                          icon: Icons.add_shopping_cart,
                          color: AppTheme.secondary,
                          onTap: _navigateToNewOrder,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.paddingLarge),

                // Recent Orders Section
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                        topRight: Radius.circular(AppTheme.borderRadiusLarge),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Orders',
                                style: AppTheme.headingLarge,
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/track'),
                                child: Text(
                                  'View All',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Orders List
                        Expanded(
                          child: _isLoadingOrders
                              ? const Center(child: CircularProgressIndicator())
                              : _recentOrders.isEmpty
                                  ? _buildEmptyOrdersState()
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.paddingMedium,
                                      ),
                                      itemCount: _recentOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = _recentOrders[index];
                                        return _buildOrderCard(order);
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Search Results Overlay
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 140, // Adjust based on search bar position
                left: AppTheme.paddingMedium,
                right: AppTheme.paddingMedium,
                child: Material(
                  elevation: 8,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return _buildSearchResultItem(result);
                      },
                    ),
                  ),
                ),
              ),

            // Loading indicator for search
            if (_isSearching)
              Positioned(
                top: 140,
                left: AppTheme.paddingMedium,
                right: AppTheme.paddingMedium,
                child: Material(
                  elevation: 8,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
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

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/order-detail',
          arguments: order.id,
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(order.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customer.name,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.name,
                          style: AppTheme.bodySmall.copyWith(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Due: ${_formatDate(order.dueDate)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.statusPending;
      case OrderStatus.inProgress:
        return AppTheme.statusInProgress;
      case OrderStatus.readyForTrial:
        return AppTheme.statusReadyForTrial;
      case OrderStatus.completed:
        return AppTheme.statusCompleted;
      case OrderStatus.cancelled:
        return AppTheme.statusCancelled;
    }
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(result.type).withOpacity(0.1),
        child: Icon(
          _getTypeIcon(result.type),
          color: _getTypeColor(result.type),
        ),
      ),
      title: Text(
        result.title,
        style: AppTheme.bodyLarge,
      ),
      subtitle: Text(
        result.subtitle,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: () => _handleSearchResultTap(result),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating your first order',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToNewOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'customer':
        return AppTheme.primary;
      case 'order':
        return AppTheme.secondary;
      case 'product':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'customer':
        return Icons.person;
      case 'order':
        return Icons.receipt;
      case 'product':
        return Icons.checkroom;
      default:
        return Icons.search;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1) return 'In $difference days';
    return '${-difference} days ago';
  }
}
