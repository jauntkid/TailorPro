import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';
import '../../services/billing_service.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _sendingNotification = false;
  bool _generatingPdf = false;

  void _shareInvoice(Order order) async {
    final ds = context.read<DataService>();
    setState(() => _generatingPdf = true);
    try {
      await BillingService.instance.shareInvoiceViaWhatsApp(
        order: order,
        shopName: ds.shopName,
        shopAddress: ds.shopAddress,
        shopPhone: ds.shopPhone,
        shopGstin: ds.shopGstin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  void _updateStatus(OrderStatus status) async {
    final ds = context.read<DataService>();
    final order = ds.getOrderById(widget.orderId);
    if (order == null) return;

    // If completing, check for pending payment
    if (status == OrderStatus.completed && order.balanceAmount > 0) {
      final paymentAction = await _showPaymentCheckDialog(order);
      if (paymentAction == null) return; // user cancelled
      if (paymentAction == 'record') {
        // Show payment dialog and wait for it, then check again
        await _showAddPaymentDialogAsync(order);
        final updatedOrder = ds.getOrderById(widget.orderId);
        if (updatedOrder == null) return;
        if (updatedOrder.balanceAmount > 0) {
          // Still has balance, ask if they want to proceed anyway
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.warning_amber_rounded,
                  size: 36, color: Theme.of(context).colorScheme.error),
              title: const Text('Pending Balance'),
              content: Text(
                  '₹${updatedOrder.balanceAmount.toStringAsFixed(0)} is still due. Complete order anyway?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Complete Anyway'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }
      // paymentAction == 'proceed' → continue without collecting
    }

    String? tailorName;
    if (status == OrderStatus.completed) {
      tailorName = await _showTailorNameDialog();
      if (tailorName == null && mounted) return;
    }
    ds.updateOrderStatus(widget.orderId, status, tailorName: tailorName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    }
    // Auto-send WhatsApp status notification to customer
    final updatedOrder = ds.getOrderById(widget.orderId);
    if (updatedOrder != null && updatedOrder.customer.phone.isNotEmpty) {
      final type =
          status == OrderStatus.readyForTrial || status == OrderStatus.completed
              ? WhatsAppNotificationType.orderReady
              : WhatsAppNotificationType.statusUpdate;
      ds.sendWhatsAppNotification(widget.orderId, type);
    }
  }

  Future<String?> _showPaymentCheckDialog(Order order) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.payment_rounded, size: 36, color: cs.primary),
          title: const Text('Payment Pending'),
          content: Text(
            '₹${order.balanceAmount.toStringAsFixed(0)} balance is due for this order.\n\nWould you like to record the payment before completing?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'proceed'),
              child: const Text('Complete Without Payment'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'record'),
              child: const Text('Record Payment'),
            ),
          ],
        );
      },
    );
  }

  Widget _imagePlaceholder(ColorScheme cs, int index) {
    return Container(
      width: 120,
      height: 120,
      color: cs.primary.withValues(alpha: 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined,
              size: 32, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text('Image ${index + 1}',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  void _showImageFullScreen(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialogAsync(Order order) async {
    final amountController =
        TextEditingController(text: order.balanceAmount.toStringAsFixed(0));
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Record Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  helperText:
                      'Balance: ₹${order.balanceAmount.toStringAsFixed(0)}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: Payment.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedMethod = v ?? 'Cash'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                context.read<DataService>().addPayment(
                      widget.orderId,
                      amount: amount,
                      method: selectedMethod,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '₹${amount.toStringAsFixed(0)} payment recorded')),
                );
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showTailorNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completed by'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final name = controller.text.trim();
            Navigator.pop(ctx, name.isEmpty ? 'Unknown' : name);
          },
          decoration: const InputDecoration(
            hintText: 'Enter staff name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(ctx, name.isEmpty ? 'Unknown' : name);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _sendWhatsAppNotification(
      Order order, WhatsAppNotificationType type) async {
    setState(() => _sendingNotification = true);
    final ds = context.read<DataService>();
    final log = await ds.sendWhatsAppNotification(widget.orderId, type);
    if (mounted) {
      setState(() => _sendingNotification = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(log.delivered
                ? '✓ ${type.label} sent via WhatsApp'
                : '✗ Failed to send')),
      );
    }
  }

  void _deleteOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded,
            size: 36, color: Theme.of(context).colorScheme.error),
        title: const Text('Delete Order?'),
        content: const Text(
            'This action cannot be undone. The order and all payment history will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<DataService>().deleteOrder(widget.orderId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order deleted')),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(Order order) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Add Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  helperText:
                      'Balance: ₹${order.balanceAmount.toStringAsFixed(0)}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: Payment.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedMethod = v ?? 'Cash'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                context.read<DataService>().addPayment(
                      widget.orderId,
                      amount: amount,
                      method: selectedMethod,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '₹${amount.toStringAsFixed(0)} payment recorded')),
                );
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final order = ds.getOrderById(widget.orderId);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Order',
            onPressed: () => Navigator.pushNamed(context, '/edit-order',
                arguments: order.id),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete Order',
            onPressed: _deleteOrder,
          ),
          PopupMenuButton<OrderStatus>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Update Status',
            onSelected: _updateStatus,
            itemBuilder: (context) => OrderStatus.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s.icon, color: s.color, size: 18),
                          const SizedBox(width: 8),
                          Text(s.label),
                          if (s == order.status) ...[
                            const Spacer(),
                            Icon(Icons.check, size: 16, color: cs.primary),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Status ────────────────────────────────────────────
          Center(child: StatusBadge(status: order.status, large: true)),
          if (order.completedByTailor != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_pin, size: 16, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Completed by ${order.completedByTailor}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w500),
                  ),
                  if (order.completedAt != null)
                    Text(
                      ' • ${DateFormat('MMM d').format(order.completedAt!)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ─── Customer Card ─────────────────────────────────────
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  order.customer.name[0],
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(order.customer.name),
              subtitle: Text(order.customer.phone),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: cs.onSurfaceVariant),
              onTap: () => Navigator.pushNamed(context, '/customer-detail',
                  arguments: order.customer.id),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Reference Images ──────────────────────────────────
          if (order.referenceImages.isNotEmpty) ...[
            _SectionLabel(
                icon: Icons.photo_library_outlined, title: 'Reference Images'),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.referenceImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final imgPath = order.referenceImages[index];
                  final isNetwork = imgPath.startsWith('http');
                  final isLocalFile = !isNetwork && File(imgPath).existsSync();

                  Widget imageWidget;
                  if (isNetwork) {
                    imageWidget = Image.network(
                      imgPath,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(cs, index),
                    );
                  } else if (isLocalFile) {
                    imageWidget = Image.file(
                      File(imgPath),
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(cs, index),
                    );
                  } else {
                    imageWidget = _imagePlaceholder(cs, index);
                  }

                  return GestureDetector(
                    onTap: () => _showImageFullScreen(
                        context, order.referenceImages, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.12)),
                        ),
                        child: imageWidget,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ─── Items ─────────────────────────────────────────────
          _SectionLabel(icon: Icons.checkroom_rounded, title: 'Items'),
          const SizedBox(height: 8),
          ...order.items.map((item) => _ItemCard(item: item)),
          const SizedBox(height: 24),

          // ─── Payment Summary & Timeline ─────────────────────────
          _SectionLabel(icon: Icons.payment_rounded, title: 'Payment'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PaymentRow(
                      label: 'Total Amount',
                      value: '₹${order.totalAmount.toStringAsFixed(0)}'),
                  _PaymentRow(
                      label: 'Advance Paid',
                      value: '₹${order.advancePaid.toStringAsFixed(0)}'),
                  if (order.payments.isNotEmpty)
                    _PaymentRow(
                      label: 'Additional Payments',
                      value:
                          '₹${order.payments.fold(0.0, (s, p) => s + p.amount).toStringAsFixed(0)}',
                    ),
                  const Divider(height: 20),
                  _PaymentRow(
                    label: 'Total Paid',
                    value: '₹${order.totalPaid.toStringAsFixed(0)}',
                    bold: true,
                    color: cs.primary,
                  ),
                  _PaymentRow(
                    label: 'Balance Due',
                    value: '₹${order.balanceAmount.toStringAsFixed(0)}',
                    bold: true,
                    color: order.balanceAmount > 0
                        ? cs.error
                        : const Color(0xFF10B981),
                  ),
                  if (order.balanceAmount > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddPaymentDialog(order),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Record Payment'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── Payment History Timeline ──────────────────────────
          if (order.advancePaid > 0 || order.payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(
                icon: Icons.timeline_rounded, title: 'Payment History'),
            const SizedBox(height: 8),
            _PaymentTimeline(order: order),
          ],
          const SizedBox(height: 24),

          // ─── Share Invoice ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _generatingPdf ? null : () => _shareInvoice(order),
              icon: _generatingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label:
                  Text(_generatingPdf ? 'Generating...' : 'Share Invoice PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── WhatsApp ──────────────────────────────────────────
          _SectionLabel(icon: Icons.chat_rounded, title: 'WhatsApp'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _WhatsAppButton(
                    icon: Icons.receipt_long,
                    label: 'Send Order Status',
                    subtitle: 'Current: ${order.status.label}',
                    loading: _sendingNotification,
                    onTap: () => _sendWhatsAppNotification(
                        order, WhatsAppNotificationType.statusUpdate),
                  ),
                  const Divider(height: 1),
                  _WhatsAppButton(
                    icon: Icons.payment,
                    label: 'Send Payment Link',
                    subtitle:
                        'Balance: ₹${order.balanceAmount.toStringAsFixed(0)}',
                    loading: _sendingNotification,
                    onTap: order.balanceAmount > 0
                        ? () => _sendWhatsAppNotification(
                            order, WhatsAppNotificationType.paymentLink)
                        : null,
                  ),
                  const Divider(height: 1),
                  _WhatsAppButton(
                    icon: Icons.check_circle_outline,
                    label: 'Send Ready Notification',
                    subtitle: 'Notify customer order is ready',
                    loading: _sendingNotification,
                    onTap: order.status == OrderStatus.completed
                        ? () => _sendWhatsAppNotification(
                            order, WhatsAppNotificationType.orderReady)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Notes ─────────────────────────────────────────────
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            _SectionLabel(icon: Icons.note_outlined, title: 'Notes'),
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(order.notes!,
                            style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── Dates ─────────────────────────────────────────────
          _SectionLabel(icon: Icons.calendar_month_outlined, title: 'Dates'),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PaymentRow(
                      label: 'Created',
                      value: DateFormat('MMM d, yyyy').format(order.createdAt)),
                  _PaymentRow(
                    label: 'Due Date',
                    value: DateFormat('MMM d, yyyy').format(order.dueDate),
                    color: order.isOverdue ? cs.error : null,
                  ),
                  if (order.completedAt != null)
                    _PaymentRow(
                      label: 'Completed',
                      value:
                          DateFormat('MMM d, yyyy').format(order.completedAt!),
                      color: cs.primary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Notification Log ──────────────────────────────────
          if (order.notifications.isNotEmpty) ...[
            _SectionLabel(
                icon: Icons.history_rounded, title: 'Notification History'),
            const SizedBox(height: 8),
            ...order.notifications.reversed.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      log.delivered ? Icons.check_circle : Icons.error_outline,
                      size: 18,
                      color: log.delivered ? const Color(0xFF25D366) : cs.error,
                    ),
                    title: Text(log.type.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      DateFormat('MMM d, h:mm a').format(log.sentAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chat,
                        size: 16, color: Color(0xFF25D366)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ─── Payment Timeline ─────────────────────────────────────────────────────────

class _PaymentTimeline extends StatelessWidget {
  final Order order;
  const _PaymentTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Build timeline entries
    final entries = <_TimelineEntry>[];

    // Order created
    entries.add(_TimelineEntry(
      icon: Icons.receipt_long_rounded,
      color: cs.primary,
      title: 'Order Created',
      subtitle: '₹${order.totalAmount.toStringAsFixed(0)} total',
      date: order.createdAt,
    ));

    // Advance payment
    if (order.advancePaid > 0) {
      entries.add(_TimelineEntry(
        icon: Icons.payments_rounded,
        color: const Color(0xFF10B981),
        title: 'Advance Paid',
        subtitle: '₹${order.advancePaid.toStringAsFixed(0)} via Cash',
        date: order.createdAt,
      ));
    }

    // Additional payments sorted by date
    final sortedPayments = [...order.payments]
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final p in sortedPayments) {
      entries.add(_TimelineEntry(
        icon: p.methodIcon,
        color: const Color(0xFF10B981),
        title: '₹${p.amount.toStringAsFixed(0)} via ${p.method}',
        subtitle: p.notes ?? 'Payment received',
        date: p.date,
      ));
    }

    // Balance remaining
    if (order.balanceAmount > 0) {
      entries.add(_TimelineEntry(
        icon: Icons.pending_rounded,
        color: cs.error,
        title: 'Balance Due',
        subtitle: '₹${order.balanceAmount.toStringAsFixed(0)} remaining',
        date: null,
      ));
    } else {
      entries.add(_TimelineEntry(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
        title: 'Fully Paid',
        subtitle: '₹${order.totalPaid.toStringAsFixed(0)} total collected',
        date: null,
      ));
    }

    return Column(
      children: entries.asMap().entries.map((e) {
        final isLast = e.key == entries.length - 1;
        final entry = e.value;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline connector
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: entry.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(entry.icon, size: 14, color: entry.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark
                              ? cs.outline.withValues(alpha: 0.12)
                              : cs.outline.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      if (entry.date != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(entry.date!),
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.35)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime? date;

  const _TimelineEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.date,
  });
}

// ─── WhatsApp Button ──────────────────────────────────────────────────────────

class _WhatsAppButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  const _WhatsAppButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null && !loading;
    const whatsAppGreen = Color(0xFF25D366);

    return ListTile(
      enabled: enabled,
      leading: Icon(icon,
          size: 20,
          color: enabled ? whatsAppGreen : cs.onSurface.withValues(alpha: 0.2)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: enabled ? 0.5 : 0.2)),
      ),
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.send_rounded,
              size: 18,
              color: enabled
                  ? whatsAppGreen
                  : cs.onSurface.withValues(alpha: 0.15)),
      onTap: onTap,
    );
  }
}

// ─── _PaymentRow ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item Card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final OrderItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.type.icon, color: cs.primary, size: 20),
          ),
          title: Text(
            '${item.type.label} ×${item.quantity}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('₹${item.price.toStringAsFixed(0)} each'),
          trailing: Text(
            '₹${item.total.toStringAsFixed(0)}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          children: [
            if (item.measurements.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: item.measurements.entries
                      .map((e) => SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                                Text('${e.value}"',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            if (item.fabricDetails != null)
              ListTile(
                dense: true,
                leading:
                    Icon(Icons.texture, size: 18, color: cs.onSurfaceVariant),
                title:
                    Text(item.fabricDetails!, style: theme.textTheme.bodySmall),
              ),
            if (item.notes != null)
              ListTile(
                dense: true,
                leading: Icon(Icons.note_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                title: Text(item.notes!, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Full Screen Image Viewer ─────────────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final imgPath = widget.images[index];
          final isNetwork = imgPath.startsWith('http');
          final isLocalFile = !isNetwork && File(imgPath).existsSync();

          Widget image;
          if (isNetwork) {
            image = InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imgPath,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: Colors.white54,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      size: 48, color: Colors.white38),
                ),
              ),
            );
          } else if (isLocalFile) {
            image = InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(imgPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      size: 48, color: Colors.white38),
                ),
              ),
            );
          } else {
            image = const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 48, color: Colors.white38),
                  SizedBox(height: 8),
                  Text('Image not available',
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return Center(child: image);
        },
      ),
    );
  }
}
