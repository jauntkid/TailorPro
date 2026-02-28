import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';

/// WhatsApp notification service using url_launcher.
/// Opens WhatsApp with pre-filled message for the customer.
class WhatsAppService {
  // Singleton
  WhatsAppService._();
  static final instance = WhatsAppService._();

  /// Opens WhatsApp with a pre-filled message for the customer.
  /// Returns a NotificationLog recording the attempt.
  Future<NotificationLog> sendNotification({
    required Order order,
    required WhatsAppNotificationType type,
    String shopUpi = '',
  }) async {
    final message = _buildMessage(order, type, shopUpi: shopUpi);
    final phone = order.customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Ensure country code — default to India if no country code
    final normalizedPhone = phone.startsWith('91') ? phone : '91$phone';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$normalizedPhone?text=$encoded');

    bool delivered = false;
    try {
      delivered = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      delivered = false;
    }

    return NotificationLog(
      type: type,
      sentAt: DateTime.now(),
      message: message,
      delivered: delivered,
    );
  }

  String _buildMessage(Order order, WhatsAppNotificationType type,
      {String shopUpi = ''}) {
    final customer = order.customer.name;

    return switch (type) {
      WhatsAppNotificationType.statusUpdate => '📌 Order Update\n\n'
          'Hi $customer,\n'
          'Your order *${order.orderNumber}* status has been updated to: *${order.status.label}*\n\n'
          '— Godukaan',
      WhatsAppNotificationType.paymentLink =>
        _buildPaymentMessage(order, customer, shopUpi),
      WhatsAppNotificationType.orderReady => '🎉 Your Order is Ready!\n\n'
          'Hi $customer,\n'
          'Great news! Your order *${order.orderNumber}* is ready for pickup.\n\n'
          '📋 Items: ${order.itemsSummary}\n'
          '📊 Balance: ₹${order.balanceAmount.toStringAsFixed(0)}\n\n'
          'Please visit us at your convenience.\n\n'
          '— Godukaan',
      WhatsAppNotificationType.deliveryReminder => '📅 Delivery Reminder\n\n'
          'Hi $customer,\n'
          'Your order *${order.orderNumber}* is due on *${_formatDate(order.dueDate)}*.\n\n'
          '📋 Items: ${order.itemsSummary}\n'
          '📊 Balance: ₹${order.balanceAmount.toStringAsFixed(0)}\n\n'
          '— Godukaan',
      WhatsAppNotificationType.custom => '📦 Hi $customer!\n\n'
          'Your order *${order.orderNumber}* has been placed.\n\n'
          '📋 Items: ${order.itemsSummary}\n'
          '💰 Total: ₹${order.totalAmount.toStringAsFixed(0)}\n'
          '📅 Due: ${_formatDate(order.dueDate)}\n\n'
          'Thank you for choosing us! ✨',
    };
  }

  String _buildPaymentMessage(Order order, String customer, String shopUpi) {
    final balance = order.balanceAmount.toStringAsFixed(0);
    final buffer = StringBuffer()
      ..write('💰 Payment Reminder\n\n')
      ..write('Hi $customer,\n')
      ..write('Order: *${order.orderNumber}*\n\n')
      ..write('Balance Due: *₹$balance*\n\n');
    if (shopUpi.isNotEmpty) {
      final upiLink = 'upi://pay?pa=$shopUpi'
          '&pn=${Uri.encodeComponent('Godukaan')}'
          '&am=${order.balanceAmount}'
          '&tn=${Uri.encodeComponent('Order ${order.orderNumber}')}';
      buffer.write('🔗 Pay via UPI: $upiLink\n\n');
    }
    buffer.write('— Godukaan');
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Preview the message that would be sent (for UI display).
  String previewMessage(Order order, WhatsAppNotificationType type,
      {String shopUpi = ''}) {
    return _buildMessage(order, type, shopUpi: shopUpi);
  }
}
