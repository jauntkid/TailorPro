import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  SettingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });
}

class PresetScreen extends StatefulWidget {
  const PresetScreen({Key? key}) : super(key: key);

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  final int _currentNavIndex = 3;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // Business details
  final TextEditingController _businessNameController =
      TextEditingController(text: 'Siri Tailors');
  final TextEditingController _businessAddressController =
      TextEditingController(text: '123 Fashion St, Mumbai, India');
  final TextEditingController _businessPhoneController =
      TextEditingController(text: '+91 9876543210');
  final TextEditingController _businessEmailController =
      TextEditingController(text: 'contact@siritailors.com');
  final TextEditingController _businessWebsiteController =
      TextEditingController(text: 'www.siritailors.com');
  final TextEditingController _googleMapsLinkController =
      TextEditingController(text: 'https://goo.gl/maps/example123');

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessWebsiteController.dispose();
    _googleMapsLinkController.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in setting.dart: $index');

    // Don't navigate if already on the selected page
    if (index == _currentNavIndex) {
      print('Already on this page, not navigating');
      return;
    }

    // Get the route from the AppBottomNav
    final String route = AppBottomNav.getRouteForIndex(index);
    print('Navigating to route: $route');

    // Navigate to the selected route and clear the navigation stack
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  Future<void> _logOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBusinessDetails() async {
          setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would save to API/backend
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call

          ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business details saved successfully'),
              backgroundColor: AppTheme.statusInProgress,
            ),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving details: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchGoogleMaps() async {
    final String mapsUrl = _googleMapsLinkController.text;
    if (await canLaunch(mapsUrl)) {
      await launch(mapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: const Text(
          'Settings & Profile',
          style: AppTheme.headingMedium,
        ),
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
                  // User profile section
                  _buildProfileSection(userData),
                  const SizedBox(height: 24),

                  // Business details section
                  const Text(
                    'Business Details',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildBusinessDetailsForm(),
                  const SizedBox(height: 24),

                  // Business QR Code
                  _buildBusinessQRCode(),
                  const SizedBox(height: 24),

                  // Google Maps location
                  _buildGoogleMapsSection(),
                  const SizedBox(height: 24),

                  // Settings options
                  _buildSettingsOptions(),
                  const SizedBox(height: 24),

                  // Log out button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: AppTheme.buttonLarge,
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

  Widget _buildProfileSection(Map<String, dynamic> userData) {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
                  children: [
            // Profile image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  userData['profileImage'] ??
                      'https://randomuser.me/api/portraits/men/32.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.primary.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                        size: 50,
                ),
              );
            },
          ),
        ),
            ),
            const SizedBox(height: 16),

            // User details
            Text(
              userData['name'] ?? 'Tailor User',
              style: AppTheme.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              userData['role'] ?? 'User',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              userData['email'] ?? 'user@example.com',
              style: AppTheme.bodyRegular,
            ),
            const SizedBox(height: 4),
            Text(
              userData['phone'] ?? '+91 9876543210',
              style: AppTheme.bodyRegular,
            ),
            const SizedBox(height: 16),

            // Edit profile button
            OutlinedButton(
            onPressed: () {
                // Navigate to edit profile page
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsForm() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
                _businessNameController, 'Business Name', Icons.business),
            const SizedBox(height: 16),
            _buildTextField(_businessAddressController, 'Business Address',
                Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(
                _businessPhoneController, 'Business Phone', Icons.phone),
            const SizedBox(height: 16),
            _buildTextField(
                _businessEmailController, 'Business Email', Icons.email),
            const SizedBox(height: 16),
            _buildTextField(
                _businessWebsiteController, 'Business Website', Icons.web),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBusinessDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save Business Details',
                  style: AppTheme.bodyRegular.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessQRCode() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Business QR Code',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              // QR code would be generated here based on business details
              // For demo purposes, using a placeholder
              child: const Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan to visit our digital storefront',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Share QR code
              },
              icon: const Icon(Icons.share),
              label: const Text('Share QR Code'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMapsSection() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Location',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            _buildTextField(
                _googleMapsLinkController, 'Google Maps Link', Icons.map),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
              // A placeholder for Google Maps preview
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 80,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchGoogleMaps,
                icon: const Icon(Icons.location_on),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Card(
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'App Theme',
            'Dark',
            Icons.brightness_6,
            () {
              // Change theme logic
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          _buildSettingItem(
            'Notifications',
            'On',
            Icons.notifications,
            () {
              // Notification settings
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          _buildSettingItem(
            'Language',
            'English',
            Icons.language,
            () {
              // Language settings
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          _buildSettingItem(
            'Currency',
            '₹ INR',
            Icons.currency_rupee,
            () {
              // Currency settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: AppTheme.bodyRegular),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTheme.bodySmall),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Container(
                decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyRegular,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}
