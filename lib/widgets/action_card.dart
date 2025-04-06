import 'package:flutter/material.dart';
import '../config/theme.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onTap;

  const ActionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          child: Stack(
            children: [
              Positioned(
                left: AppTheme.paddingLarge,
                top: AppTheme.paddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingMedium,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: AppTheme.paddingMedium,
                bottom: 0,
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.5),
                  size: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
