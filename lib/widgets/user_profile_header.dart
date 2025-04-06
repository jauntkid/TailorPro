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
    return Padding(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
                SizedBox(width: AppTheme.paddingMedium),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, $name',
                      style: AppTheme.headingMedium,
                    ),
                    Text(
                      role,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotificationTap,
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
