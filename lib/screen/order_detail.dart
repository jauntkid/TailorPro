import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';

class OrderItem {
  final String name;
  final String description;
  final String quantity;
  final double price;
  final IconData icon;

  OrderItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.icon,
  });
}

class ChecklistItem {
  final String title;
  final bool isCompleted;

  ChecklistItem({
    required this.title,
    required this.isCompleted,
  });
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int _currentNavIndex = 0;
  final String _orderNumber = '#20255001';
  final String _customerName = 'John Smith';
  final String _customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
  final String _dueDate = 'Jan 15';
  final int _itemCount = 2;
  final String _status = 'In Progress';
  final String _notes =
      'Customer requested express delivery. Blouse needs extra embroidery work on sleeves. Contact before final stitching.';

  final List<OrderItem> _orderItems = [
    OrderItem(
      name: 'Designer Blouse',
      description: 'Blue, Size: M',
      quantity: 'Qty: 2',
      price: 259.00,
      icon: Icons.design_services,
    ),
    OrderItem(
      name: 'Bridal Lehenga',
      description: 'Red, Size: L',
      quantity: 'Qty: 1',
      price: 899.00,
      icon: Icons.checkroom,
    ),
  ];

  final List<ChecklistItem> _checklistItems = [
    ChecklistItem(
      title: 'Design Approved',
      isCompleted: true,
    ),
    ChecklistItem(
      title: 'Reference Checked',
      isCompleted: true,
    ),
    ChecklistItem(
      title: 'Customer Review',
      isCompleted: false,
    ),
  ];

  void _handleNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _markAsCompleted() {
    // Implement order completion logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order marked as completed'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _showNotifications() {
    // Implement notification functionality
  }

  double get _totalPrice {
    return _orderItems.fold(0, (sum, item) => sum + item.price);
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

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Card
                      _buildOrderSummaryCard(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Order Items Card
                      _buildOrderItemsCard(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Progress Checklist Card
                      _buildProgressChecklistCard(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Order Notes Card
                      _buildOrderNotesCard(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Mark as Completed Button
                      _buildMarkAsCompletedButton(),

                      SizedBox(height: AppTheme.paddingLarge),
                    ],
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

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _orderNumber,
              style: AppTheme.headingLarge,
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_itemCount Items • Due $_dueDate',
                  style: AppTheme.bodySmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.share,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.paddingMedium),
                    IconButton(
                      icon: Icon(Icons.print,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(_customerImage),
                ),
                SizedBox(width: AppTheme.paddingSmall),
                Text(
                  _customerName,
                  style: AppTheme.bodyLarge,
                ),
                Spacer(),
                _buildStatusBadge(_status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: AppTheme.paddingMedium),
            ...List.generate(
              _orderItems.length,
              (index) => _buildOrderItemRow(
                  _orderItems[index], index != _orderItems.length - 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 36,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      item.quantity,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Per piece',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: AppTheme.dividerColor),
      ],
    );
  }

  Widget _buildProgressChecklistCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Checklist',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: AppTheme.paddingMedium),
            ...List.generate(
              _checklistItems.length,
              (index) => _buildChecklistItem(_checklistItems[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                item.isCompleted ? Icons.check : Icons.hourglass_empty,
                size: 14,
                color: item.isCompleted ? Colors.green.shade800 : Colors.grey,
              ),
            ),
          ),
          SizedBox(width: AppTheme.paddingMedium),
          Text(
            item.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Notes',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              _notes,
              style: TextStyle(
                color: const Color(0xFFCBCBCB),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkAsCompletedButton() {
    return ElevatedButton(
      onPressed: _markAsCompleted,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2563EB), const Color(0xFF4F46E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mark as Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Icon(Icons.check_circle_outline, color: Colors.white),
            ],
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
