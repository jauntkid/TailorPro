import 'package:flutter/material.dart';
import '../config/theme.dart';

class OrderCard extends StatelessWidget {
  final String customerName;
  final String orderNumber;
  final String items;
  final String dueDate;
  final double price;
  final String status;
  final VoidCallback onTap;
  final String currencySymbol;

  const OrderCard({
    Key? key,
    required this.customerName,
    required this.orderNumber,
    required this.items,
    required this.dueDate,
    required this.price,
    required this.status,
    required this.onTap,
    this.currencySymbol = '\$',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      customerName,
                      style: AppTheme.bodyLarge,
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Text(
                  orderNumber,
                  style: AppTheme.bodySmall,
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$items • Due $dueDate',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '$currencySymbol${price.toStringAsFixed(2)}',
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
        backgroundColor = AppTheme.statusInProgressBg;
        textColor = AppTheme.statusInProgress;
        break;
      case 'Ready':
        backgroundColor = AppTheme.statusReadyBg;
        textColor = AppTheme.statusReady;
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
