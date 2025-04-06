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
      padding: const EdgeInsets.fromLTRB(
        AppTheme.paddingMedium,
        AppTheme.paddingSmall,
        AppTheme.paddingMedium,
        AppTheme.paddingMedium,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              onProfileTap();
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome,',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppTheme.headingMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
