import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';
import '../../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  final OrderStatus? initialFilter;
  final bool showOverdue;
  const OrdersScreen({super.key, this.initialFilter, this.showOverdue = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  OrderStatus? _selectedStatus;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter;
    _showOverdueOnly = widget.showOverdue;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final ds = context.read<DataService>();
      if (ds.hasMoreOrders && !ds.isLoadingMore) {
        ds.loadMoreOrders();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    var orders = dataService.getOrders(
      status: _selectedStatus,
      search: _searchController.text,
    );
    if (_showOverdueOnly) {
      final now = DateTime.now();
      orders = orders
          .where((o) =>
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.cancelled &&
              o.dueDate.isBefore(DateTime(now.year, now.month, now.day)))
          .toList();
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          // ─── Search ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ─── Filter chips ───────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterPill(
                  label: 'All',
                  selected: _selectedStatus == null && !_showOverdueOnly,
                  onTap: () => setState(() {
                    _selectedStatus = null;
                    _showOverdueOnly = false;
                  }),
                ),
                _FilterPill(
                  label: 'Overdue',
                  selected: _showOverdueOnly,
                  onTap: () => setState(() {
                    _showOverdueOnly = !_showOverdueOnly;
                    if (_showOverdueOnly) _selectedStatus = null;
                  }),
                  dotColor: Colors.redAccent,
                ),
                ...OrderStatus.values
                    .where((s) => s != OrderStatus.cancelled)
                    .map(
                      (status) => _FilterPill(
                        label: status.label,
                        selected:
                            _selectedStatus == status && !_showOverdueOnly,
                        onTap: () => setState(() {
                          _showOverdueOnly = false;
                          _selectedStatus =
                              _selectedStatus == status ? null : status;
                        }),
                        dotColor: status.color,
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── List ───────────────────────────────────────────────
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 36,
                          color: cs.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedStatus != null
                              ? 'No ${_selectedStatus!.label.toLowerCase()} orders'
                              : 'No orders found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        orders.length + (dataService.hasMoreOrders ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= orders.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final order = orders[index];
                      final nextStatus = order.status.nextStatus;
                      final canAdvance = nextStatus != null;
                      return Dismissible(
                        key: ValueKey(order.id),
                        direction: canAdvance
                            ? DismissDirection.horizontal
                            : DismissDirection.endToStart,
                        // Right swipe → advance status (only when canAdvance)
                        background: canAdvance
                            ? Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color:
                                      nextStatus.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_forward_rounded,
                                        color: nextStatus.color),
                                    const SizedBox(width: 8),
                                    Text(
                                      nextStatus.label,
                                      style: TextStyle(
                                        color: nextStatus.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Left-swipe delete (used as primary background when no advance)
                            : Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child:
                                    Icon(Icons.delete_rounded, color: cs.error),
                              ),
                        secondaryBackground: canAdvance
                            ? Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child:
                                    Icon(Icons.delete_rounded, color: cs.error),
                              )
                            : null,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Advance status
                            if (nextStatus == null) return false;
                            // If completing, check for pending payment
                            if (nextStatus == OrderStatus.completed &&
                                order.balanceAmount > 0) {
                              final action = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  icon: Icon(Icons.payment_rounded,
                                      size: 36, color: cs.primary),
                                  title: const Text('Payment Pending'),
                                  content: Text(
                                    '₹${order.balanceAmount.toStringAsFixed(0)} is still due.\nRecord payment or send a reminder.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, 'cancel'),
                                      child: const Text('Cancel'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.pop(ctx, 'reminder'),
                                      icon: const Icon(Icons.send_rounded,
                                          size: 18),
                                      label: const Text('Send Reminder'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx, 'open');
                                        Navigator.pushNamed(
                                          context,
                                          '/order-detail',
                                          arguments: order.id,
                                        );
                                      },
                                      icon: const Icon(Icons.payment_rounded,
                                          size: 18),
                                      label: const Text('Record Payment'),
                                    ),
                                  ],
                                ),
                              );
                              if (action == 'reminder') {
                                dataService.sendWhatsAppNotification(order.id,
                                    WhatsAppNotificationType.paymentLink);
                              }
                              return false; // Don't advance status
                            }
                            dataService.updateOrderStatus(order.id, nextStatus);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${order.orderNumber} → ${nextStatus.label}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return false; // Don't remove from list
                          }
                          // Delete
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              icon: Icon(Icons.delete_forever_rounded,
                                  size: 36, color: cs.error),
                              title: const Text('Delete Order?'),
                              content: Text(
                                  'Delete ${order.orderNumber}? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: cs.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          dataService.deleteOrder(order.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${order.orderNumber} deleted')),
                          );
                        },
                        child: OrderCard(
                          order: order,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(
                              context,
                              '/order-detail',
                              arguments: order.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.pushNamed(context, '/create-order'),
        tooltip: 'New Order',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Minimal filter pill ──────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF141414) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.25)
                  : cs.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
