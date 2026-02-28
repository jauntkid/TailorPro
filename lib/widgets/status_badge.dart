import 'package:flutter/material.dart';
import '../models/order.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: large ? 14 : 11, color: status.color),
          SizedBox(width: large ? 5 : 3),
          Text(
            status.label,
            style: TextStyle(
              fontSize: large ? 13 : 10,
              fontWeight: FontWeight.w600,
              color: status.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
