import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/app_bottom_nav.dart';
import '../config/theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _apiService = ApiService();
  List<Customer> _customers = [];
  bool _isLoading = true;
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  String? _searchQuery;
  final _searchController = TextEditingController();
  final int _currentNavIndex = 1; // Set to 1 for Customers page

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _isLoading = true;
        _customers = [];
      });
    } else if (!_hasMore || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getCustomers(
      page: _page,
      limit: _limit,
      search: _searchQuery,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        final List<dynamic> customersData = result['data'] ?? [];
        final List<Customer> newCustomers =
            customersData.map((json) => Customer.fromJson(json)).toList();

        _customers.addAll(newCustomers);
        _hasMore = newCustomers.length >= _limit;
        if (_hasMore) _page++;
      } else {
        ErrorHandler.showError(
            context, result['error'] ?? 'Failed to load customers');
      }
    });
  }

  void _search() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadCustomers(refresh: true);
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in customers_screen.dart: $index');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCustomers(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-customer')
                .then((_) => _loadCustomers(refresh: true)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = null;
                    });
                    _loadCustomers(refresh: true);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _customers.isEmpty && !_isLoading
                ? const Center(child: Text('No customers found'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        _loadCustomers();
                      }
                      return true;
                    },
                    child: ListView.builder(
                      itemCount: _customers.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _customers.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final customer = _customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(customer.name[0]),
                          ),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/customer-details',
                            arguments: customer.id,
                          ).then((_) => _loadCustomers(refresh: true)),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-customer')
            .then((_) => _loadCustomers(refresh: true)),
        tooltip: 'Add Customer',
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }
}
