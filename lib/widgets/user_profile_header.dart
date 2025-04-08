import 'package:flutter/material.dart';
import '../config/theme.dart';

class UserProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final String profileImageUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const UserProfileHeader({
    Key? key,
    required this.name,
    required this.role,
    required this.profileImageUrl,
    required this.onProfileTap,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/user_profile');
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(profileImageUrl),
              onBackgroundImageError: (_, __) {
                // Fallback for image loading error
              },
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: AppTheme.paddingMedium),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationTap,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}
