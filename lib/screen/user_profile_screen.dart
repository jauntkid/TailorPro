import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic>? _businessData;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Loading User Data ===');

      // Get user data from AuthProvider first
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('AuthProvider user data: ${authProvider.userData}');

      if (authProvider.userData != null) {
        setState(() {
          _userData = authProvider.userData!;
        });
        print('Set user data from AuthProvider: $_userData');
      }

      // Fetch fresh user data from API
      print('Fetching user data from API...');
      final userResult = await _apiService.getCurrentUser();
      print('API Response: $userResult');

      if (userResult['success'] && userResult['data'] != null) {
        setState(() {
          _userData = userResult['data'];
        });
        print('Set user data from API: $_userData');
      } else {
        print('Failed to get user data from API: ${userResult['error']}');
      }

      // If user has a business, fetch business details
      if (_userData['business'] != null) {
        print('Fetching business data for ID: ${_userData['business']}');
        final businessResult =
            await _apiService.getBusinessById(_userData['business']);
        print('Business API Response: $businessResult');

        if (businessResult['success'] && businessResult['data'] != null) {
          setState(() {
            _businessData = businessResult['data'];
          });
          print('Set business data: $_businessData');
        } else {
          print('Failed to get business data: ${businessResult['error']}');
        }
      } else {
        print('No business ID found in user data');
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('=== Finished Loading User Data ===');
    }
  }

  void _handleNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    final route = AppBottomNav.getRouteForIndex(index);
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: const Text('Profile', style: AppTheme.headingMedium),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildProfileSection(),
                  const SizedBox(height: AppTheme.paddingLarge),

                  // Business Section (if available)
                  if (_businessData != null) ...[
                    _buildBusinessSection(),
                    const SizedBox(height: AppTheme.paddingLarge),
                  ],

                  // Statistics Section
                  _buildStatisticsSection(),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              _userData['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg',
            ),
            onBackgroundImageError: (_, __) {
              // Fallback for image loading error
            },
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // User Details
          Text(
            _userData['name'] ?? 'Unknown User',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            _userData['role'] ?? 'User',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Contact Info
          _buildInfoRow(Icons.email, _userData['email'] ?? 'No email'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildInfoRow(Icons.phone, _userData['phone'] ?? 'No phone'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildInfoRow(
              Icons.location_on, _userData['address'] ?? 'No address'),
        ],
      ),
    );
  }

  Widget _buildBusinessSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Details', style: AppTheme.headingMedium),
          const SizedBox(height: AppTheme.paddingMedium),
          _buildInfoRow(
              Icons.business, _businessData!['name'] ?? 'No business name'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildInfoRow(
              Icons.location_on, _businessData!['address'] ?? 'No address'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildInfoRow(Icons.phone, _businessData!['phone'] ?? 'No phone'),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildInfoRow(Icons.email, _businessData!['email'] ?? 'No email'),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistics', style: AppTheme.headingMedium),
          const SizedBox(height: AppTheme.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                  'Orders', _userData['totalOrders']?.toString() ?? '0'),
              _buildStatCard(
                  'Customers', _userData['totalCustomers']?.toString() ?? '0'),
              _buildStatCard('Revenue',
                  '₹${_userData['totalRevenue']?.toString() ?? '0'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.paddingSmall),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyRegular,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
