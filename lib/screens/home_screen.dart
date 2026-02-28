import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/data_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index, {OrderStatus? filter, bool? showOverdue})?
      onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ds = context.watch<DataService>();

    final hasQuery = _searchController.text.isNotEmpty;
    Map<String, List<dynamic>>? searchResults;
    if (hasQuery) {
      searchResults = ds.globalSearch(_searchController.text);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search orders, customers...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (_) => setState(() {}),
              )
            : Text(
                ds.shopName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: cs.primary,
                  fontFamily: 'Georgia',
                ),
              ),
        actions: _isSearching
            ? [
                IconButton(
                  icon: Icon(Icons.image_search_rounded, color: cs.primary),
                  tooltip: 'AI Image Search',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'AI Image Search is still in development. Stay tuned!')),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.search_rounded,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isSearching = true);
                  },
                ),
              ],
      ),
      body: _isSearching && hasQuery
          ? _SearchResultsView(
              results: searchResults!,
              cs: cs,
              theme: Theme.of(context),
            )
          : ds.orders.isEmpty && ds.customers.isEmpty
              ? _WelcomeView(onSwitchTab: widget.onSwitchTab)
              : _DashboardView(ds: ds, cs: cs, onSwitchTab: widget.onSwitchTab),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  final Map<String, List<dynamic>> results;
  final ColorScheme cs;
  final ThemeData theme;

  const _SearchResultsView({
    required this.results,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final orders = results['orders'] as List<dynamic>;
    final customers = results['customers'] as List<dynamic>;
    final isDark = theme.brightness == Brightness.dark;

    if (orders.isEmpty && customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 40, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text('No results found',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (customers.isNotEmpty) ...[
          _SearchSectionTitle(
              title: 'Customers', count: customers.length, cs: cs),
          const SizedBox(height: 6),
          ...customers.map((c) {
            final customer = c as Customer;
            return _SearchCustomerTile(
                customer: customer, cs: cs, isDark: isDark);
          }),
          const SizedBox(height: 16),
        ],
        if (orders.isNotEmpty) ...[
          _SearchSectionTitle(title: 'Orders', count: orders.length, cs: cs),
          const SizedBox(height: 6),
          ...orders.map((o) {
            final order = o as Order;
            return _SearchOrderTile(order: order, cs: cs, isDark: isDark);
          }),
        ],
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final ColorScheme cs;
  const _SearchSectionTitle(
      {required this.title, required this.count, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary.withValues(alpha: 0.7),
                letterSpacing: 0.5)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.primary)),
        ),
      ],
    );
  }
}

class _SearchCustomerTile extends StatelessWidget {
  final Customer customer;
  final ColorScheme cs;
  final bool isDark;
  const _SearchCustomerTile(
      {required this.customer, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(context, '/customer-detail',
                arguments: customer.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Text(customer.name[0].toUpperCase(),
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(customer.phone,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchOrderTile extends StatelessWidget {
  final Order order;
  final ColorScheme cs;
  final bool isDark;
  const _SearchOrderTile(
      {required this.order, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(context, '/order-detail', arguments: order.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(order.status.icon,
                      size: 18, color: order.status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(order.customer.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(order.orderNumber,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.35))),
                      ]),
                      const SizedBox(height: 2),
                      Text(order.itemsSummary,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text('₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(int index, {OrderStatus? filter, bool? showOverdue})?
      onSwitchTab;
  const _WelcomeView({this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cut, size: 64, color: cs.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            Text(
              'Welcome to Godukaan',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first customer or creating an order',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _BigActionButton(
                    icon: Icons.add,
                    label: 'New Order',
                    filled: true,
                    onTap: () => Navigator.pushNamed(context, '/create-order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigActionButton(
                    icon: Icons.person_add_outlined,
                    label: 'Add Customer',
                    filled: false,
                    onTap: () => Navigator.pushNamed(context, '/add-customer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final DataService ds;
  final ColorScheme cs;
  final void Function(int index, {OrderStatus? filter, bool? showOverdue})?
      onSwitchTab;

  const _DashboardView({
    required this.ds,
    required this.cs,
    this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final orders = ds.orders;
    final now = DateTime.now();

    final newOrders =
        orders.where((o) => o.status == OrderStatus.pending).length;
    final inProgress =
        orders.where((o) => o.status == OrderStatus.inProgress).length;
    final ready =
        orders.where((o) => o.status == OrderStatus.readyForTrial).length;
    final overdue = orders
        .where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled &&
            o.dueDate.isBefore(now))
        .length;

    final dueOrders = orders
        .where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .toList()
      ..sort((a, b) {
        if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
        return a.dueDate.compareTo(b.dueDate);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Quick Stats — 2x2
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              label: 'New Orders',
              value: '$newOrders',
              icon: Icons.fiber_new_rounded,
              color: Colors.amber,
              onTap: () => onSwitchTab?.call(1, filter: OrderStatus.pending),
            ),
            _StatCard(
              label: 'In Progress',
              value: '$inProgress',
              icon: Icons.engineering_rounded,
              color: Colors.blue,
              onTap: () => onSwitchTab?.call(1, filter: OrderStatus.inProgress),
            ),
            _StatCard(
              label: 'Ready',
              value: '$ready',
              icon: Icons.checkroom_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () =>
                  onSwitchTab?.call(1, filter: OrderStatus.readyForTrial),
            ),
            _StatCard(
              label: 'Overdue',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
              onTap: () => onSwitchTab?.call(1, showOverdue: true),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Actions — big square-ish buttons
        Row(
          children: [
            Expanded(
              child: _BigActionButton(
                icon: Icons.add,
                label: 'New Order',
                filled: true,
                onTap: () => Navigator.pushNamed(context, '/create-order'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigActionButton(
                icon: Icons.person_add_outlined,
                label: 'Add Customer',
                filled: false,
                onTap: () => Navigator.pushNamed(context, '/add-customer'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Due / Overdue orders
        if (dueOrders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Due',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => onSwitchTab?.call(1),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...dueOrders.take(6).map((o) => _CompactOrderTile(order: o, cs: cs)),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: cs.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color.withValues(alpha: 0.8)),
                const SizedBox(width: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Big Action Button ────────────────────────────────────────────────────────

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: filled ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: filled ? cs.onPrimary : cs.primary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: filled ? cs.onPrimary : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact Order Tile ───────────────────────────────────────────────────────

class _CompactOrderTile extends StatelessWidget {
  final Order order;
  final ColorScheme cs;

  const _CompactOrderTile({required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isOverdue = order.dueDate.isBefore(DateTime.now()) &&
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled;
    final daysUntilDue = order.dueDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color.lerp(cs.surface, order.status.color, 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.redAccent.withValues(alpha: 0.3)
              : order.status.color.withValues(alpha: 0.18),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/order-detail', arguments: order.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  order.status.icon,
                  size: 20,
                  color: order.status.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (order.isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            order.customer.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${order.items.length} item${order.items.length == 1 ? '' : 's'} \u2022 \u20B9${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isOverdue
                    ? '${-daysUntilDue}d overdue'
                    : daysUntilDue == 0
                        ? 'Due today'
                        : 'Due in ${daysUntilDue}d',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? Colors.redAccent : cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
