import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';

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

  // Mock user data - in a real app, this would be fetched from the database
  final Map<String, dynamic> _userData = {
    'name': 'John Smith',
    'phoneNumber': '+91 9876543210',
    'address': '123 Main Street, Bangalore, Karnataka, India',
    'referral': 'Friend Recommendation',
    'notes': 'Regular customer, prefers tailored suits.',
    'profileImage': 'https://randomuser.me/api/portraits/men/1.jpg',
  };

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
    await Future.delayed(Duration(seconds: 2));

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
    setState(() {
      _currentNavIndex = index;
    });
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
        title: Text('Delete Customer', style: AppTheme.headingMedium),
        content: Text(
            'Are you sure you want to delete this customer? This action cannot be undone.',
            style: AppTheme.bodyRegular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Customer deleted'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetail() {
    Navigator.pushNamed(context, '/order_detail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Customer Profile', style: AppTheme.headingLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _navigateBack,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textPrimary),
            onPressed: _editCustomer,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppTheme.accentColor),
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
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
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
      margin: EdgeInsets.all(AppTheme.paddingMedium),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        children: [
          // Profile image and name
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_userData['profileImage']),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['name'],
                      style: AppTheme.headingMedium,
                    ),
                    SizedBox(height: 4),
                    _buildInfoRow(Icons.phone, _userData['phoneNumber']),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppTheme.paddingMedium),
          Divider(color: AppTheme.dividerColor),
          SizedBox(height: AppTheme.paddingMedium),

          // Other details
          _buildInfoRow(Icons.location_on, _userData['address']),
          SizedBox(height: AppTheme.paddingSmall),

          _buildInfoRow(Icons.people, 'Referral: ${_userData['referral']}'),
          SizedBox(height: AppTheme.paddingSmall),

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
        SizedBox(width: 8),
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
      margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
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
            padding: EdgeInsets.all(AppTheme.paddingMedium),
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

                SizedBox(height: AppTheme.paddingSmall),

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
      padding: EdgeInsets.symmetric(
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
