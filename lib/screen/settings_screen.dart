import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final int _currentNavIndex = 3;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = '₹';
  final List<String> _languages = ['English', 'Hindi', 'Tamil', 'Telugu'];
  final List<String> _currencies = ['₹', '\$', '€', '£'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load saved settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedCurrency = prefs.getString('currency') ?? '₹';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('currency', _selectedCurrency);
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex) return;
    final String route = AppBottomNav.getRouteForIndex(index);
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  Future<void> _handleLogout() async {
    try {
      final result = await _apiService.logout();
      if (result['success']) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to logout')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTheme.headingMedium),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        children: [
          // App Theme
          _buildSection(
            title: 'App Theme',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode', style: AppTheme.bodyRegular),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                    _saveSettings();
                  });
                },
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Notifications
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications',
                    style: AppTheme.bodyRegular),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                    _saveSettings();
                  });
                },
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Language
          _buildSection(
            title: 'Language',
            children: [
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language, style: AppTheme.bodyRegular),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                      _saveSettings();
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                    vertical: AppTheme.paddingSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Currency
          _buildSection(
            title: 'Currency',
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: _currencies.map((String currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency, style: AppTheme.bodyRegular),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCurrency = newValue;
                      _saveSettings();
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                    vertical: AppTheme.paddingSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Product Management
          _buildSection(
            title: 'Product Management',
            children: [
              ListTile(
                title: const Text('Create New Product',
                    style: AppTheme.bodyRegular),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  Navigator.pushNamed(context, '/new_product');
                },
              ),
              ListTile(
                title:
                    const Text('Manage Products', style: AppTheme.bodyRegular),
                trailing: const Icon(Icons.manage_search),
                onTap: () {
                  Navigator.pushNamed(context, '/products');
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),

          // Logout Button
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppTheme.paddingLarge),
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headingSmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
