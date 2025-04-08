import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'order_detail.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _customer;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final int _currentNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Fetching customer details for ID: ${widget.customerId}');
      final customerResult =
          await _apiService.getCustomerById(widget.customerId);
      final ordersResult =
          await _apiService.getCustomerOrders(widget.customerId);

      print('Customer API response: $customerResult');
      print('Orders API response: $ordersResult');

      if (customerResult['success'] && customerResult['data'] != null) {
        // Handle nested data structure if present
        var customerData = customerResult['data'];
        if (customerData is Map && customerData.containsKey('data')) {
          customerData = customerData['data'];
        }

        print('Processed customer data: $customerData');

        // Handle orders data
        List<dynamic> orders = [];
        if (ordersResult['success'] && ordersResult['data'] != null) {
          var ordersData = ordersResult['data'];
          if (ordersData is Map && ordersData.containsKey('data')) {
            orders = ordersData['data'] ?? [];
          } else if (ordersData is List) {
            orders = ordersData;
          }
        }

        setState(() {
          _customer = {
            'name': customerData['name'] ?? 'Unknown Customer',
            'phone': customerData['phone'] ?? 'No phone number',
            'email': customerData['email'],
            'address': customerData['address'],
            'image': customerData['profileImage'] ??
                customerData['image'] ??
                'https://randomuser.me/api/portraits/men/1.jpg',
          };
          _orders = orders;
          _isLoading = false;
        });
      } else {
        print('Failed to fetch customer data: ${customerResult['error']}');
        throw Exception(
            customerResult['error'] ?? 'Failed to load customer data');
      }
    } catch (e) {
      print('Error fetching customer details: $e');
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

  void _handleNavTap(int index) {
    print('Navigation tapped in customer_detail.dart: $index');

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

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notifications
  }

  void _navigateToOrderDetail(String orderId) {
    Navigator.pushNamed(
      context,
      '/order_detail',
      arguments: {'id': orderId},
    );
  }

  void _navigateToEditCustomer() {
    Navigator.pushNamed(
      context,
      '/edit_customer',
      arguments: {'id': widget.customerId},
    ).then((_) => _fetchCustomerDetails());
  }

  @override
  Widget build(BuildContext context) {
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

                  // Customer Info Card
                  Container(
                    margin: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  _customer?['name']?[0]?.toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _customer?['name'] ?? 'Unknown Customer',
                                      style: AppTheme.headingMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _customer?['phone'] ?? 'No phone number',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _navigateToEditCustomer,
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                          if (_customer?['email'] != null) ...[
                            const SizedBox(height: AppTheme.paddingMedium),
                            _buildInfoRow(Icons.email, _customer!['email']),
                          ],
                          if (_customer?['address'] != null) ...[
                            const SizedBox(height: AppTheme.paddingSmall),
                            _buildInfoRow(
                                Icons.location_on, _customer!['address']),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Orders Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Orders (${_orders.length})',
                          style: AppTheme.headingMedium,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/new_order',
                              arguments: {'customerId': widget.customerId},
                            ).then((_) => _fetchCustomerDetails());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Order'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child: _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No orders yet',
                                  style: AppTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/new_order',
                                      arguments: {
                                        'customerId': widget.customerId
                                      },
                                    ).then((_) => _fetchCustomerDetails());
                                  },
                                  child: const Text(
                                    'Create first order',
                                    style: TextStyle(color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.all(AppTheme.paddingMedium),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              final dueDate = order['dueDate'] != null
                                  ? DateTime.parse(order['dueDate'])
                                  : null;
                              final status = order['status'] ?? 'New';

                              return Card(
                                margin: const EdgeInsets.only(
                                    bottom: AppTheme.paddingMedium),
                                color: AppTheme.cardBackground,
                                child: ListTile(
                                  title: Text(
                                    order['orderNumber'] ?? 'No number',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Due: ${dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate) : 'Not set'}',
                                        style: AppTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onTap: () =>
                                      _navigateToOrderDetail(order['_id']),
                                ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Urgent':
        return AppTheme.statusUrgent;
      case 'In Progress':
        return AppTheme.statusInProgress;
      case 'Ready':
        return AppTheme.statusReady;
      case 'Completed':
        return AppTheme.statusCompleted;
      default:
        return AppTheme.textSecondary;
    }
  }
}
