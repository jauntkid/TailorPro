import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(color: AppTheme.border.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.home_outlined,
                Icons.home_filled,
                'Home',
              ),
              _buildNavItem(
                context,
                1,
                Icons.person_outline,
                Icons.person,
                'Analytics',
              ),
              _buildNavItem(
                context,
                2,
                Icons.calendar_today_outlined,
                Icons.calendar_today,
                'Calendar',
              ),
              _buildNavItem(
                context,
                3,
                Icons.tune_outlined,
                Icons.tune,
                'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData iconOutlined,
      IconData iconFilled, String label) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Calendar':
            Navigator.pushNamed(context, '/track');
            break;
          case 'Analytics':
            Navigator.pushNamed(context, '/user_page');
            break;
          case 'Settings':
            Navigator.pushNamed(context, '/preset');
            break;
          default:
            Navigator.pushNamed(context, '/');
          //onTap(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.tabLabel.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
