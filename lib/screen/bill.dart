import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/user_profile_header.dart';

class BillItem {
  final String name;
  final String description;
  final double price;
  final String? imagePath;
  final IconData? icon;

  BillItem({
    required this.name,
    required this.description,
    required this.price,
    this.imagePath,
    this.icon,
  });
}

class BillScreen extends StatefulWidget {
  const BillScreen({Key? key}) : super(key: key);

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  int _currentNavIndex = 0;
  final String _orderNumber = '#20255001';
  final String _customerName = 'John Smith';
  final String _customerImage = 'https://randomuser.me/api/portraits/men/1.jpg';
  final String _dueDate = 'Jan 15';
  final int _itemCount = 2;
  final String _status = 'In Progress';

  final List<BillItem> _billItems = [
    BillItem(
      name: 'Formal Shirt',
      description: 'Cotton, White',
      price: 85.00,
      icon: Icons.checkroom,
    ),
    BillItem(
      name: 'Suit Vest',
      description: 'Black, Slim Fit',
      price: 120.00,
      icon: Icons.dry_cleaning,
    ),
  ];

  double get _subtotal {
    return _billItems.fold(0, (sum, item) => sum + item.price);
  }

  double get _total {
    // No tax or additional costs in this example
    return _subtotal;
  }

  void _handleNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_page');
  }

  void _showNotifications() {
    // Implement notification functionality
  }

  void _sendOnWhatsApp() {
    // Would implement WhatsApp integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending invoice via WhatsApp...'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _showInvoice() {
    // Would implement invoice display
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing invoice...'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _downloadInvoice() {
    // Would implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading invoice...'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
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
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_itemCount Items • Due $_dueDate',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.share,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppTheme.paddingMedium),
                                      Icon(
                                        Icons.print,
                                        color: AppTheme.textSecondary,
                                        size: 20,
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
                                    backgroundImage:
                                        NetworkImage(_customerImage),
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
                      ),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Order Items Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
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

                              // Order items list
                              ...List.generate(
                                _billItems.length,
                                (index) => _buildBillItemRow(_billItems[index],
                                    index == _billItems.length - 1),
                              ),

                              Divider(color: AppTheme.dividerColor),

                              // Subtotal
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppTheme.paddingSmall),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${_subtotal.toStringAsFixed(2)}',
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Total
                              Padding(
                                padding:
                                    EdgeInsets.only(top: AppTheme.paddingSmall),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: AppTheme.headingMedium,
                                    ),
                                    Text(
                                      '\$${_total.toStringAsFixed(2)}',
                                      style: AppTheme.headingMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Action Buttons
                      ElevatedButton(
                        onPressed: _sendOnWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMedium),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat),
                            SizedBox(width: AppTheme.paddingSmall),
                            Text(
                              'Send on WhatsApp',
                              style: AppTheme.buttonLarge,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppTheme.paddingMedium),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _showInvoice,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                foregroundColor: Colors.black,
                                side: BorderSide(color: AppTheme.borderColor),
                                minimumSize: Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt),
                                  SizedBox(width: AppTheme.paddingSmall),
                                  Text(
                                    'Invoice',
                                    style: AppTheme.buttonMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: AppTheme.paddingMedium),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _downloadInvoice,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                foregroundColor: Colors.black,
                                side: BorderSide(color: AppTheme.borderColor),
                                minimumSize: Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download),
                                  SizedBox(width: AppTheme.paddingSmall),
                                  Text(
                                    'Download',
                                    style: AppTheme.buttonMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBillItemRow(BillItem item, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    item.icon ?? Icons.inventory_2,
                    size: 24,
                    color: Colors.black54,
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
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: AppTheme.dividerColor),
      ],
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
