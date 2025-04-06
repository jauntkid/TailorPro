import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bottom_nav.dart';

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
  int _currentNavIndex = 3; // Settings is typically the last tab
  String _selectedTheme = 'Dark';
  String _selectedCurrency = 'INR (₹)';
  bool _isLoggedIn = true;

  // Default pricing values
  final Map<String, double> _defaultPricing = {
    'Shirt': 499.00,
    'Pant': 699.00,
    'Suit': 2999.00,
    'Blouse': 799.00,
    'Saree': 599.00,
  };

  void _handleNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Select Theme', style: AppTheme.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Dark', 'Dark mode (Default)'),
            _buildThemeOption('Light', 'Light mode'),
            _buildThemeOption('System', 'Follow system settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme, String description) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: theme,
        groupValue: _selectedTheme,
        activeColor: AppTheme.primary,
        onChanged: (value) {
          setState(() {
            _selectedTheme = value!;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme changed to $value'),
              backgroundColor: AppTheme.statusInProgress,
            ),
          );
        },
      ),
      title: Text(theme, style: AppTheme.bodyLarge),
      subtitle: Text(description, style: AppTheme.bodySmall),
    );
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Select Currency', style: AppTheme.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('INR (₹)', 'Indian Rupee (Default)'),
            _buildCurrencyOption('USD (\$)', 'US Dollar'),
            _buildCurrencyOption('EUR (€)', 'Euro'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String description) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: currency,
        groupValue: _selectedCurrency,
        activeColor: AppTheme.primary,
        onChanged: (value) {
          setState(() {
            _selectedCurrency = value!;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Currency changed to $value'),
              backgroundColor: AppTheme.statusInProgress,
            ),
          );
        },
      ),
      title: Text(currency, style: AppTheme.bodyLarge),
      subtitle: Text(description, style: AppTheme.bodySmall),
    );
  }

  void _showPricingEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Default Pricing', style: AppTheme.headingMedium),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _defaultPricing.length,
            itemBuilder: (context, index) {
              String key = _defaultPricing.keys.elementAt(index);
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(key, style: AppTheme.bodyLarge),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        style: AppTheme.bodyRegular,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: AppTheme.bodyRegular,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primary),
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        controller: TextEditingController(
                            text: _defaultPricing[key]!.toStringAsFixed(2)),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _defaultPricing[key] =
                                double.tryParse(value) ?? _defaultPricing[key]!;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pricing updated'),
                  backgroundColor: AppTheme.statusInProgress,
                ),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleLogin() {
    setState(() {
      _isLoggedIn = !_isLoggedIn;
    });

    if (_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in successfully'),
          backgroundColor: AppTheme.statusInProgress,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppTheme.accentColor,
        ),
      );

      // In a real app, you would navigate to the login screen
      // Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showUserInfoEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit Business Info', style: AppTheme.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: AppTheme.bodyRegular,
              decoration: InputDecoration(
                labelText: 'Business Name',
                labelStyle: AppTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.borderColor),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              controller: TextEditingController(text: 'Siri Tailors'),
            ),
            SizedBox(height: 16),
            TextField(
              style: AppTheme.bodyRegular,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: AppTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.borderColor),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              controller: TextEditingController(text: '+91 9876543210'),
            ),
            SizedBox(height: 16),
            TextField(
              style: AppTheme.bodyRegular,
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: AppTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.borderColor),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              controller: TextEditingController(text: '123 Main St, Bangalore'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Business info updated'),
                  backgroundColor: AppTheme.statusInProgress,
                ),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  List<SettingOption> get _settingOptions => [
        SettingOption(
          icon: Icons.color_lens,
          title: 'Theme',
          subtitle: '$_selectedTheme Mode',
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: AppTheme.textSecondary),
          onTap: _showThemeSelector,
        ),
        SettingOption(
          icon: Icons.currency_rupee,
          title: 'Currency',
          subtitle: _selectedCurrency,
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: AppTheme.textSecondary),
          onTap: _showCurrencySelector,
        ),
        SettingOption(
          icon: Icons.monetization_on,
          title: 'Default Pricing',
          subtitle: 'Set default prices for items',
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: AppTheme.textSecondary),
          onTap: _showPricingEditor,
        ),
        SettingOption(
          icon: Icons.business,
          title: 'Business Info',
          subtitle: 'Edit your business details',
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: AppTheme.textSecondary),
          onTap: _showUserInfoEditor,
        ),
        SettingOption(
          icon: _isLoggedIn ? Icons.logout : Icons.login,
          title: _isLoggedIn ? 'Logout' : 'Login',
          subtitle: _isLoggedIn
              ? 'Sign out of your account'
              : 'Sign in to your account',
          onTap: _toggleLogin,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Settings', style: AppTheme.headingLarge),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          itemCount: _settingOptions.length,
          separatorBuilder: (context, index) => Divider(
            color: AppTheme.dividerColor,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final option = _settingOptions[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: AppTheme.paddingSmall,
                horizontal: AppTheme.paddingMedium,
              ),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  option.icon,
                  color: option.title == 'Logout'
                      ? AppTheme.accentColor
                      : AppTheme.primary,
                ),
              ),
              title: Text(
                option.title,
                style: AppTheme.bodyLarge,
              ),
              subtitle: Text(
                option.subtitle,
                style: AppTheme.bodySmall,
              ),
              trailing: option.trailing,
              onTap: option.onTap,
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }
}
