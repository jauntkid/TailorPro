import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import '../providers/auth_provider.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final int orderCount;
  final String? lastOrderDate;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.orderCount,
    this.lastOrderDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Customer',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      orderCount: json['orderCount'] ?? 0,
      lastOrderDate: json['lastOrderDate'],
    );
  }
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final ApiService _apiService = ApiService();
  List<Customer> _customers = [];
  bool _isLoading = true;
  final int _currentNavIndex = 1; // Set to 1 for customers page
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({String? search}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.getCustomers(
        search: search,
        page: 1,
        limit: 20,
      );
      if (result['success'] == true) {
        List<dynamic> customersJson = [];

        // Handle different API response structures
        if (result['data'] is List) {
          customersJson = result['data'];
        } else if (result['data'] is Map &&
            result['data'].containsKey('data')) {
          customersJson = result['data']['data'];
        }

        List<Customer> parsedCustomers = [];
        for (var json in customersJson) {
          try {
            parsedCustomers.add(Customer.fromJson(json));
          } catch (e) {
            print('Error parsing customer: $e');
          }
        }

        setState(() {
          _customers = parsedCustomers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Failed to load customers')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching customers: $e')),
      );
    }
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in customers.dart: $index');

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

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.pushNamed(
      context,
      '/customer_detail',
      arguments: {'id': customer.id},
    );
  }

  void _navigateToNewCustomer() {
    Navigator.pushNamed(context, '/new_customer').then((_) {
      _fetchCustomers(); // Refresh customers list when returning
    });
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notifications
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with user profile information
            UserProfileHeader(
              name: userData['name'] ?? 'Tailor User',
              role: userData['role'] ?? 'User',
              profileImageUrl: userData['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg',
              onProfileTap: _navigateToProfile,
              onNotificationTap: _showNotifications,
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                onChanged: (value) {
                  _fetchCustomers(search: value);
                },
              ),
            ),

            // Add Customer Button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium),
              child: ElevatedButton.icon(
                onPressed: _navigateToNewCustomer,
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.paddingMedium),

            // Customers List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No customers found',
                                style: AppTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _navigateToNewCustomer,
                                child: const Text(
                                  'Add your first customer',
                                  style: TextStyle(color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                  bottom: AppTheme.paddingMedium),
                              color: AppTheme.cardBackground,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primary.withOpacity(0.1),
                                  child: Text(
                                    customer.name[0].toUpperCase(),
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.phone,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (customer.orderCount > 0)
                                      Text(
                                        '${customer.orderCount} orders • Last order: ${customer.lastOrderDate ?? 'N/A'}',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right,
                                    color: AppTheme.textSecondary),
                                onTap: () =>
                                    _navigateToCustomerDetail(customer),
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
}
