import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/customer.dart';
import '../../services/data_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodDays = 7;
  DateTimeRange? _customRange;

  void _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 14)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _periodDays = range.end.difference(range.start).inDays + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final revenueData = ds.getRevenueByDay(_periodDays);
    final ordersData = ds.getOrdersByDay(_periodDays);
    final topCustomers = ds.getTopCustomers(limit: 5);
    final itemsByType = ds.getItemsByType();
    final avgTurnaround = ds.getAvgTurnaroundDays();
    final collectionRate = ds.getCollectionRate();
    final monthlyRevenue = ds.getMonthlyRevenue();
    final busiestDays = ds.getBusiestDays();

    // Period-filtered stats for summary cards
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays));
    final periodOrders =
        ds.orders.where((o) => o.createdAt.isAfter(cutoff)).toList();
    final totalRevenue = periodOrders.fold(0.0, (sum, o) => sum + o.totalPaid);
    final totalOrders = periodOrders.length;
    final completed =
        periodOrders.where((o) => o.status == OrderStatus.completed).length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completionRate =
        totalOrders > 0 ? (completed / totalOrders * 100) : 0.0;

    // Period-filtered status breakdown
    final stats = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      stats[status] = periodOrders.where((o) => o.status == status).length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Period selector ─────────────────────────────────
            _PeriodSelector(
              selected: _periodDays,
              customRange: _customRange,
              onChanged: (d) => setState(() {
                _periodDays = d;
                _customRange = null;
              }),
              onCustom: _pickCustomRange,
            ),
            const SizedBox(height: 20),

            // ─── Summary cards ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Revenue',
                    value: '₹${_formatNum(totalRevenue)}',
                    icon: Icons.currency_rupee,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Orders',
                    value: '$totalOrders',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Avg Value',
                    value: '₹${_formatNum(avgOrderValue)}',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Completion',
                    value: '${completionRate.toStringAsFixed(0)}%',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── Revenue chart ──────────────────────────────────
            _ChartSection(
              title: 'Revenue',
              icon: Icons.show_chart_rounded,
              color: const Color(0xFF10B981),
              cs: cs,
              theme: theme,
              child: _BarChart(
                data: revenueData
                    .map((e) => MapEntry(
                        _periodDays > 14
                            ? DateFormat('MMM d').format(e.key)
                            : DateFormat('EEE').format(e.key),
                        e.value))
                    .toList(),
                color: const Color(0xFF10B981),
                formatValue: (v) => '₹${_formatNum(v)}',
                isDark: isDark,
                cs: cs,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Orders chart ───────────────────────────────────
            _ChartSection(
              title: 'New Orders',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF3B82F6),
              cs: cs,
              theme: theme,
              child: _BarChart(
                data: ordersData
                    .map((e) => MapEntry(
                        _periodDays > 14
                            ? DateFormat('MMM d').format(e.key)
                            : DateFormat('EEE').format(e.key),
                        e.value.toDouble()))
                    .toList(),
                color: const Color(0xFF3B82F6),
                formatValue: (v) => v.toStringAsFixed(0),
                isDark: isDark,
                cs: cs,
              ),
            ),
            const SizedBox(height: 24),

            // ─── 7-Day Revenue Trend Line Chart ─────────────────
            _ChartSection(
              title: 'Revenue Trend',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFD4A574),
              cs: cs,
              theme: theme,
              child: _LineChart(
                data: revenueData
                    .map((e) =>
                        MapEntry(DateFormat('EEE').format(e.key), e.value))
                    .toList(),
                color: const Color(0xFFD4A574),
                formatValue: (v) => '₹${_formatNum(v)}',
                isDark: isDark,
                cs: cs,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Day-wise Report ────────────────────────────────
            _DayWiseReport(
              revenueData: revenueData,
              ordersData: ordersData,
              cs: cs,
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // ─── Status breakdown ───────────────────────────────
            _StatusBreakdown(
                stats: stats, cs: cs, theme: theme, isDark: isDark),
            const SizedBox(height: 24),

            // ─── Top customers ──────────────────────────────────
            if (topCustomers.isNotEmpty)
              _TopCustomersSection(
                customers: topCustomers,
                cs: cs,
                theme: theme,
                isDark: isDark,
              ),
            const SizedBox(height: 24),

            // ─── Additional metrics row ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Avg Turnaround',
                    value: '${avgTurnaround.toStringAsFixed(1)}d',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Collection',
                    value: '${(collectionRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF14B8A6),
                    isDark: isDark,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Monthly revenue chart ──────────────────────────
            _ChartSection(
              title: 'Monthly Revenue',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFF59E0B),
              cs: cs,
              theme: theme,
              child: _BarChart(
                data: monthlyRevenue,
                color: const Color(0xFFF59E0B),
                formatValue: (v) => '₹${_formatNum(v)}',
                isDark: isDark,
                cs: cs,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Busiest days chart ─────────────────────────────
            _ChartSection(
              title: 'Busiest Days',
              icon: Icons.calendar_view_week_rounded,
              color: const Color(0xFF8B5CF6),
              cs: cs,
              theme: theme,
              child: _BarChart(
                data: busiestDays.entries
                    .map((e) => MapEntry(e.key, e.value.toDouble()))
                    .toList(),
                color: const Color(0xFF8B5CF6),
                formatValue: (v) => v.toStringAsFixed(0),
                isDark: isDark,
                cs: cs,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Items by type breakdown ────────────────────────
            if (itemsByType.isNotEmpty)
              _ItemsByTypeSection(
                items: itemsByType,
                cs: cs,
                theme: theme,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  static String _formatNum(double v) {
    if (v >= 100000) return '${(v / 1000).toStringAsFixed(0)}K';
    if (v >= 1000) return NumberFormat('#,##0').format(v.round());
    return v.toStringAsFixed(0);
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final DateTimeRange? customRange;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustom;
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.onCustom,
    this.customRange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const periods = [
      (7, '7 days'),
      (30, '30 days'),
      (90, '90 days'),
    ];

    final isCustom = customRange != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...periods.map((p) {
          final isSelected = selected == p.$1 && !isCustom;
          return GestureDetector(
            onTap: () => onChanged(p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: onCustom,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCustom
                  ? cs.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCustom
                    ? cs.primary.withValues(alpha: 0.4)
                    : cs.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range_rounded,
                    size: 14,
                    color: isCustom
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  isCustom
                      ? '${DateFormat('MMM d').format(customRange!.start)} – ${DateFormat('MMM d').format(customRange!.end)}'
                      : 'Custom',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCustom ? FontWeight.w600 : FontWeight.w400,
                    color: isCustom
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5),
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

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ColorScheme cs;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Section ────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  final ThemeData theme;
  final Widget child;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.cs,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final Color color;
  final String Function(double) formatValue;
  final bool isDark;
  final ColorScheme cs;

  const _BarChart({
    required this.data,
    required this.color,
    required this.formatValue,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final chartHeight = 140.0;

    // Show max 10 bars
    final displayData = data.length > 10 ? _aggregateData(data, 10) : data;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: SizedBox(
        height: chartHeight + 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: displayData.map((entry) {
            final barHeight =
                maxVal > 0 ? (entry.value / maxVal * chartHeight) : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.value > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          formatValue(entry.value),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: max(barHeight, 2),
                      decoration: BoxDecoration(
                        color: entry.value > 0
                            ? color
                            : cs.outline.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _aggregateData(
      List<MapEntry<String, double>> data, int buckets) {
    final result = <MapEntry<String, double>>[];
    final step = (data.length / buckets).ceil();
    for (var i = 0; i < data.length; i += step) {
      final end = min(i + step, data.length);
      final chunk = data.sublist(i, end);
      final sum = chunk.fold(0.0, (s, e) => s + e.value);
      result.add(MapEntry(chunk.first.key, sum));
    }
    return result;
  }
}

// ─── Status Breakdown ─────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  final Map<OrderStatus, int> stats;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;

  const _StatusBreakdown({
    required this.stats,
    required this.cs,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.donut_small_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Status Breakdown',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: OrderStatus.values.map((status) {
              final count = stats[status] ?? 0;
              final fraction = total > 0 ? count / total : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(status.icon, size: 16, color: status.color),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: cs.outline.withValues(alpha: 0.08),
                          color: status.color,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Top Customers ────────────────────────────────────────────────────────────

class _TopCustomersSection extends StatelessWidget {
  final List<MapEntry<Customer, double>> customers;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;

  const _TopCustomersSection({
    required this.customers,
    required this.cs,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Top Customers',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: List.generate(customers.length, (i) {
              final entry = customers[i];
              final customer = entry.key;
              final revenue = entry.value;
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  customer.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  customer.phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                trailing: Text(
                  '₹${NumberFormat('#,##0').format(revenue.round())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/customer-detail',
                  arguments: customer.id,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Items by Type ────────────────────────────────────────────────────────────

class _ItemsByTypeSection extends StatelessWidget {
  final Map<String, int> items;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;

  const _ItemsByTypeSection({
    required this.items,
    required this.cs,
    required this.theme,
    required this.isDark,
  });

  static const _typeColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checkroom_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Items by Type',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: List.generate(sorted.length, (i) {
              final entry = sorted[i];
              final fraction = total > 0 ? entry.value / total : 0.0;
              final color = _typeColors[i % _typeColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: cs.outline.withValues(alpha: 0.08),
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final Color color;
  final String Function(double) formatValue;
  final bool isDark;
  final ColorScheme cs;

  const _LineChart({
    required this.data,
    required this.color,
    required this.formatValue,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('No data',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 13)),
        ),
      );
    }

    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    const chartHeight = 120.0;
    const chartPadding = 32.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight + chartPadding,
            child: CustomPaint(
              size: Size(double.infinity, chartHeight + chartPadding),
              painter: _LineChartPainter(
                data: data.map((e) => e.value).toList(),
                color: color,
                maxVal: maxVal,
                chartHeight: chartHeight,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((e) {
              return Expanded(
                child: Text(
                  e.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxVal;
  final double chartHeight;

  _LineChartPainter({
    required this.data,
    required this.color,
    required this.maxVal,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final path = Path();
    final fillPath = Path();
    final segW = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * segW;
      final y = chartHeight - (maxVal > 0 ? data[i] / maxVal * chartHeight : 0);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill area
    fillPath.lineTo((data.length - 1) * segW, chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    canvas.drawPath(path, paint);

    // Dots
    for (var i = 0; i < data.length; i++) {
      final x = i * segW;
      final y = chartHeight - (maxVal > 0 ? data[i] / maxVal * chartHeight : 0);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()
            ..color = const Color(0xFF0A0A0A)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.data != data || old.color != color;
}

// ─── Day-wise Report ──────────────────────────────────────────────────────────

class _DayWiseReport extends StatelessWidget {
  final List<MapEntry<DateTime, double>> revenueData;
  final List<MapEntry<DateTime, int>> ordersData;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;

  const _DayWiseReport({
    required this.revenueData,
    required this.ordersData,
    required this.cs,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (revenueData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Day-wise Report',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Date',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.5)))),
                    Expanded(
                        flex: 2,
                        child: Text('Revenue',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.5)))),
                    Expanded(
                        flex: 2,
                        child: Text('Orders',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.5)))),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Rows — show most recent first
              ...List.generate(revenueData.length, (i) {
                final revIdx = revenueData.length - 1 - i;
                final date = revenueData[revIdx].key;
                final revenue = revenueData[revIdx].value;
                final orders =
                    revIdx < ordersData.length ? ordersData[revIdx].value : 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? Colors.transparent
                        : cs.outline.withValues(alpha: 0.03),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          DateFormat('EEE, MMM d').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${NumberFormat('#,##0').format(revenue.round())}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: revenue > 0
                                ? const Color(0xFF10B981)
                                : cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$orders',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: orders > 0
                                ? const Color(0xFF3B82F6)
                                : cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
