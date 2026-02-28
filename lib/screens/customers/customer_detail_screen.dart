import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../widgets/order_card.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final customer = dataService.getCustomerById(customerId);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final orders = dataService.getOrders(customerId: customerId);
    final totalRevenue = dataService.getTotalRevenueForCustomer(customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit customer',
            onPressed: () => Navigator.pushNamed(
              context,
              '/edit-customer',
              arguments: customer.id,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete customer',
            onPressed: () => _confirmDelete(context, dataService),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Profile Card ───────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.phone, text: customer.phone),
                  if (customer.email != null)
                    _InfoRow(icon: Icons.email_outlined, text: customer.email!),
                  if (customer.address != null)
                    _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: customer.address!),
                  if (customer.notes != null)
                    _InfoRow(icon: Icons.note_outlined, text: customer.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Stats ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Orders',
                  value: '${orders.length}',
                  icon: Icons.receipt_long_outlined,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                  cs: cs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Measurement Templates ──────────────────────────────────
          _MeasurementTemplatesSection(
            customerId: customerId,
            dataService: dataService,
          ),
          const SizedBox(height: 24),

          // ─── Orders Section ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orders',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/create-order',
                  arguments: customer,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Order'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No orders yet for this customer',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...orders.map(
              (order) => OrderCard(
                order: order,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/order-detail',
                  arguments: order.id,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DataService dataService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text(
            'This action cannot be undone. All associated data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dataService.deleteCustomer(customerId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Private Widgets ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Measurement Templates Section ────────────────────────────────────────────

class _MeasurementTemplatesSection extends StatelessWidget {
  final String customerId;
  final DataService dataService;

  const _MeasurementTemplatesSection({
    required this.customerId,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final templates = dataService.getTemplates(customerId: customerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.straighten_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Measurement Templates',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (templates.isNotEmpty)
              Text(
                '${templates.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (templates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(Icons.straighten_rounded,
                    size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 6),
                Text(
                  'No saved templates yet',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Templates are saved during order creation',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11),
                ),
              ],
            ),
          )
        else
          ...templates.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(t.garmentType.icon, color: cs.primary, size: 18),
                    ),
                    title: Text(t.label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(t.garmentType.label,
                        style: theme.textTheme.bodySmall),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: cs.error.withValues(alpha: 0.6)),
                      onPressed: () {
                        dataService.deleteTemplate(t.id);
                      },
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: t.measurements.entries
                              .map((e) => SizedBox(
                                    width: 80,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.key,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color:
                                                        cs.onSurfaceVariant)),
                                        Text('${e.value}"',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // ─── Measurement History ───
                      if (t.history.length > 1) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 14,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 6),
                              Text(
                                'History (${t.history.length} records)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        ...t.history.reversed.take(5).map((snap) {
                          final dateStr =
                              '${snap.recordedAt.day}/${snap.recordedAt.month}/${snap.recordedAt.year}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(dateStr,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11)),
                                      if (snap.orderNumber != null) ...[
                                        const SizedBox(width: 8),
                                        Text(snap.orderNumber!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.4),
                                                    fontSize: 10)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children:
                                        snap.measurements.entries.map((e) {
                                      // Compare with current measurements
                                      final current = t.measurements[e.key];
                                      final changed =
                                          current != null && current != e.value;
                                      return Text(
                                        '${e.key}: ${e.value}"',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: changed
                                              ? cs.error.withValues(alpha: 0.7)
                                              : cs.onSurface
                                                  .withValues(alpha: 0.5),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
