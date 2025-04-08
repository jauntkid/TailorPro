import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({Key? key}) : super(key: key);

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _originalOrders = []; // Store original orders
  List<dynamic> _displayedOrders = []; // Store filtered and grouped orders
  final int _currentNavIndex = 2; // Set to 2 for track page
  String _selectedStatus = 'All'; // Default status filter

  // Status options for filtering
  final List<String> _statusOptions = [
    'All',
    'New',
    'In Progress',
    'Partially Ready',
    'Ready',
    'Urgent',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _apiService.getOrders();
      if (response['success']) {
        // Handle different API response structures
        List<dynamic> ordersData = [];
        if (response['data'] is List) {
          ordersData = response['data'];
        } else if (response['data'] is Map &&
            response['data'].containsKey('data')) {
          ordersData = response['data']['data'];
        } else {
          throw Exception('Invalid orders data format');
        }

        setState(() {
          _originalOrders = ordersData; // Store original orders
          _sortOrdersByDeadline(); // Apply initial filter
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to load orders');
      }
    } catch (e) {
      print('Error loading orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortOrdersByDeadline() {
    // Flatten all items from all orders
    List<Map<String, dynamic>> allItems = [];
    for (var order in _originalOrders) {
      // Use _originalOrders instead of _orders
      if (order['items'] == null || order['items'] is! List) continue;

      for (var item in order['items']) {
        // Apply status filter
        if (_selectedStatus != 'All' && item['status'] != _selectedStatus) {
          continue;
        }

        // Safely get customer name with fallback
        String customerName = 'Unknown Customer';
        if (order['customer'] != null) {
          if (order['customer'] is Map) {
            customerName = order['customer']['name'] ?? 'Unknown Customer';
          } else if (order['customer'] is String) {
            customerName = 'Customer #${order['customer']}';
          }
        }

        // Safely get order number with fallback
        String orderNumber = order['orderNumber'] ?? 'No number';

        // Safely get deadline with fallback
        String deadline = item['deadline'] ??
            order['dueDate'] ??
            DateTime.now().toIso8601String();

        allItems.add({
          ...item,
          'orderId': order['_id'] ?? '',
          'orderNumber': orderNumber,
          'customerName': customerName,
          'deadline': deadline,
        });
      }
    }

    // Sort items by deadline and status (urgent first)
    allItems.sort((a, b) {
      try {
        final deadlineA = DateTime.parse(a['deadline']);
        final deadlineB = DateTime.parse(b['deadline']);

        // If same date, sort by status (urgent first)
        if (deadlineA.isAtSameMomentAs(deadlineB)) {
          if (a['status'] == 'Urgent' && b['status'] != 'Urgent') return -1;
          if (a['status'] != 'Urgent' && b['status'] == 'Urgent') return 1;
        }

        return deadlineA.compareTo(deadlineB);
      } catch (e) {
        return 0; // If parsing fails, keep original order
      }
    });

    // Group items by deadline date
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in allItems) {
      try {
        final deadline = DateTime.parse(item['deadline']);
        final dateKey = DateFormat('yyyy-MM-dd').format(deadline);

        if (!groupedItems.containsKey(dateKey)) {
          groupedItems[dateKey] = [];
        }
        groupedItems[dateKey]!.add(item);
      } catch (e) {
        // Skip items with invalid dates
        continue;
      }
    }

    // Convert to list format for display
    setState(() {
      _displayedOrders = groupedItems.entries.map((entry) {
        return {
          'date': entry.key,
          'items': entry.value,
        };
      }).toList();
    });
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

  Future<void> _updateItemStatus(
      String orderId, String itemId, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // If status is Partially Ready, show item completion dialog
      if (newStatus == 'Partially Ready') {
        final result = await _showItemCompletionDialog(orderId);
        if (result == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final response =
          await _apiService.updateOrderStatus(orderId, itemId, newStatus);
      if (response['success']) {
        await _loadOrders(); // Reload orders to reflect changes
      } else {
        throw Exception(response['error'] ?? 'Failed to update status');
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showItemCompletionDialog(String orderId) async {
    // Fetch order details to get all items
    final orderResponse = await _apiService.getOrderById(orderId);
    if (!orderResponse['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to fetch order details: ${orderResponse['error']}'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return null;
    }

    final orderData = orderResponse['data'];
    final items = orderData['items'] as List<dynamic>;
    final Map<String, bool> itemCompletion = {};

    // Initialize all items as completed by default
    for (var item in items) {
      itemCompletion[item['_id']] = true;
    }

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title:
                  const Text('Item Completion', style: AppTheme.headingMedium),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select which items are completed:',
                      style: AppTheme.bodyRegular,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    ...items.map((item) {
                      return CheckboxListTile(
                        title: Text(
                          item['productName'] ?? 'Unknown Item',
                          style: AppTheme.bodyRegular,
                        ),
                        value: itemCompletion[item['_id']] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            itemCompletion[item['_id']] = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primary,
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Check if all items are completed
                    final allCompleted =
                        itemCompletion.values.every((value) => value);
                    Navigator.pop(context, true);

                    // If all items are completed, update status to Ready
                    if (allCompleted) {
                      _updateItemStatus(orderId, '', 'Ready');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStatusUpdateDialog(
      String orderId, String itemId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Update Status', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption('New', currentStatus, orderId, itemId),
              _buildStatusOption('In Progress', currentStatus, orderId, itemId),
              _buildStatusOption(
                  'Partially Ready', currentStatus, orderId, itemId),
              _buildStatusOption('Ready', currentStatus, orderId, itemId),
              _buildStatusOption('Urgent', currentStatus, orderId, itemId),
              _buildStatusOption('Completed', currentStatus, orderId, itemId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
      String status, String currentStatus, String orderId, String itemId) {
    return ListTile(
      title: Text(status, style: AppTheme.bodyRegular),
      leading: Icon(
        Icons.circle,
        color: _getStatusColor(status),
      ),
      onTap: () {
        Navigator.pop(context);
        _updateItemStatus(orderId, itemId, status);
      },
      selected: status == currentStatus,
    );
  }

  void _navigateToOrderDetail(String orderId) {
    Navigator.pushNamed(
      context,
      '/order_detail',
      arguments: {'id': orderId},
    );
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in track.dart: $index');

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
                  UserProfileHeader(
                    name: userData['name'] ?? 'Tailor',
                    role: userData['role'] ?? 'User',
                    profileImageUrl: userData['profileImage'] ??
                        'https://randomuser.me/api/portraits/men/32.jpg',
                    onProfileTap: () {},
                    onNotificationTap: () {},
                  ),
                  // Status filter buttons
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMedium,
                        vertical: AppTheme.paddingSmall),
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      itemBuilder: (context, index) {
                        final status = _statusOptions[index];
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = status;
                                _sortOrdersByDeadline(); // Re-apply filter
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? _getStatusColor(status)
                                  : AppTheme.cardBackground,
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : _getStatusColor(status),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                            child: Text(status),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      itemCount: _displayedOrders
                          .length, // Use _displayedOrders instead of _orders
                      itemBuilder: (context, index) {
                        final group = _displayedOrders[
                            index]; // Use _displayedOrders instead of _orders
                        final date = DateTime.parse(group['date']);
                        final items = group['items'] as List<dynamic>;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.paddingMedium),
                              child: Text(
                                DateFormat('MMMM d, yyyy').format(date),
                                style: AppTheme.headingMedium,
                              ),
                            ),
                            ...items
                                .map((item) => _buildItemCard(item))
                                .toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex, // Use the state variable
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    // Safely get item ID with fallback
    String itemId = item['_id'] ?? '';

    // Safely get order ID with fallback
    String orderId = item['orderId'] ?? '';

    // Safely get status with fallback
    String status = item['status'] ?? 'New';

    // Safely get deadline with fallback
    DateTime deadline;
    try {
      deadline =
          DateTime.parse(item['deadline'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      deadline = DateTime.now();
    }

    final isOverdue =
        deadline.isBefore(DateTime.now()) && status != 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      color: AppTheme.cardBackground,
      child: InkWell(
        onTap: () => _navigateToOrderDetail(orderId),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['orderNumber'] ?? 'No number',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                item['customerName'] ?? 'Unknown Customer',
                style: AppTheme.bodyRegular,
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${DateFormat('MMM d, h:mm a').format(deadline)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: isOverdue
                          ? AppTheme.statusUrgent
                          : AppTheme.textSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showStatusUpdateDialog(
                      orderId,
                      itemId,
                      status,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
