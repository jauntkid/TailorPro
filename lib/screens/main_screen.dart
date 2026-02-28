import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import 'home_screen.dart';
import 'orders/orders_screen.dart';
import 'customers/customers_screen.dart';
import 'settings/settings_screen.dart';
import 'analytics/analytics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  OrderStatus? _orderFilter;
  bool _showOverdue = false;

  void _switchTab(int index, {OrderStatus? filter, bool? showOverdue}) {
    setState(() {
      _currentIndex = index;
      _orderFilter = filter;
      _showOverdue = showOverdue ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onSwitchTab: _switchTab),
          OrdersScreen(
            key: ValueKey('orders_${_orderFilter}_$_showOverdue'),
            initialFilter: _orderFilter,
            showOverdue: _showOverdue,
          ),
          const CustomersScreen(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => _switchTab(i),
        cs: cs,
        isDark: isDark,
      ),
    );
  }
}

class _AnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ColorScheme cs;
  final bool isDark;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.cs,
    required this.isDark,
  });

  static const _items = [
    _NavItem(Icons.space_dashboard_outlined, Icons.space_dashboard, 'Home'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
    _NavItem(Icons.people_outline, Icons.people, 'Customers'),
    _NavItem(Icons.analytics_outlined, Icons.analytics, 'Analytics'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final itemWidth = MediaQuery.of(context).size.width / _items.length;

    return Container(
      height: 68 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Sliding top indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: currentIndex * itemWidth + (itemWidth - 40) / 2,
            top: 0,
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(3)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // Nav items
          Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            key: ValueKey('$i-$selected'),
                            size: 24,
                            color: selected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: selected ? 11 : 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
