import 'package:flutter/material.dart';
import 'customer.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  inProgress,
  readyForTrial,
  completed,
  cancelled;

  String get label => switch (this) {
        pending => 'Pending',
        inProgress => 'In Progress',
        readyForTrial => 'Ready for Pickup',
        completed => 'Completed',
        cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        pending => const Color(0xFFF59E0B),
        inProgress => const Color(0xFF3B82F6),
        readyForTrial => const Color(0xFF8B5CF6),
        completed => const Color(0xFF10B981),
        cancelled => const Color(0xFFEF4444),
      };

  IconData get icon => switch (this) {
        pending => Icons.schedule_rounded,
        inProgress => Icons.engineering_rounded,
        readyForTrial => Icons.local_shipping_rounded,
        completed => Icons.check_circle_rounded,
        cancelled => Icons.cancel_rounded,
      };

  /// Next status in the workflow (null if already completed/cancelled).
  OrderStatus? get nextStatus => switch (this) {
        pending => inProgress,
        inProgress => readyForTrial,
        readyForTrial => completed,
        completed => null,
        cancelled => null,
      };
}

enum GarmentType {
  shirt,
  trouser,
  suit,
  sherwani,
  kurta,
  blouse,
  lehenga,
  saree,
  dress,
  other;

  String get label => switch (this) {
        shirt => 'Shirt',
        trouser => 'Trouser',
        suit => 'Suit',
        sherwani => 'Sherwani',
        kurta => 'Kurta',
        blouse => 'Blouse',
        lehenga => 'Lehenga',
        saree => 'Saree Blouse',
        dress => 'Dress',
        other => 'Other',
      };

  IconData get icon => switch (this) {
        shirt => Icons.inventory_2_outlined,
        trouser => Icons.inventory_2_outlined,
        suit => Icons.business_center,
        sherwani => Icons.inventory_2_outlined,
        kurta => Icons.inventory_2_outlined,
        blouse => Icons.inventory_2_outlined,
        lehenga => Icons.inventory_2_outlined,
        saree => Icons.inventory_2_outlined,
        dress => Icons.inventory_2_outlined,
        other => Icons.category,
      };

  List<String> get defaultMeasurements => switch (this) {
        shirt => ['Chest', 'Shoulder', 'Sleeve Length', 'Shirt Length', 'Neck'],
        trouser => ['Waist', 'Hip', 'Inseam', 'Outseam'],
        suit => [
            'Chest',
            'Shoulder',
            'Sleeve Length',
            'Jacket Length',
            'Waist',
            'Hip'
          ],
        sherwani => [
            'Chest',
            'Shoulder',
            'Sleeve Length',
            'Sherwani Length',
            'Neck'
          ],
        kurta => ['Chest', 'Shoulder', 'Sleeve Length', 'Kurta Length', 'Neck'],
        blouse => ['Bust', 'Shoulder', 'Sleeve Length', 'Blouse Length'],
        lehenga => ['Waist', 'Hip', 'Lehenga Length'],
        saree => ['Bust', 'Shoulder', 'Sleeve Length', 'Blouse Length'],
        dress => ['Bust', 'Waist', 'Hip', 'Dress Length', 'Shoulder'],
        other => ['Custom 1', 'Custom 2', 'Custom 3'],
      };
}

enum WhatsAppNotificationType {
  statusUpdate,
  paymentLink,
  orderReady,
  deliveryReminder,
  custom;

  String get label => switch (this) {
        statusUpdate => 'Status Update',
        paymentLink => 'Payment Link',
        orderReady => 'Order Ready',
        deliveryReminder => 'Delivery Reminder',
        custom => 'Custom',
      };
}

// ─── NotificationLog ──────────────────────────────────────────────────────────

class NotificationLog {
  final WhatsAppNotificationType type;
  final DateTime sentAt;
  final String message;
  final bool delivered;

  const NotificationLog({
    required this.type,
    required this.sentAt,
    required this.message,
    required this.delivered,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sentAt': sentAt.toIso8601String(),
        'message': message,
        'delivered': delivered,
      };

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      type: WhatsAppNotificationType.values.byName(json['type'] as String),
      sentAt: DateTime.parse(json['sentAt'] as String),
      message: json['message'] as String,
      delivered: json['delivered'] as bool,
    );
  }
}

// ─── Payment ──────────────────────────────────────────────────────────────────

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String? notes;

  const Payment({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    this.notes,
  });

  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Cheque',
    'Google Pay',
    'PhonePe',
    'Paytm',
    'Net Banking',
  ];

  IconData get methodIcon => switch (method.toLowerCase()) {
        'cash' => Icons.payments_rounded,
        'upi' => Icons.smartphone_rounded,
        'card' => Icons.credit_card_rounded,
        'bank transfer' => Icons.account_balance_rounded,
        'cheque' => Icons.receipt_long_rounded,
        'google pay' || 'phonepe' || 'paytm' => Icons.phone_android_rounded,
        'net banking' => Icons.language_rounded,
        _ => Icons.payment_rounded,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'method': method,
        'notes': notes,
      };

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      method: json['method'] as String,
      notes: json['notes'] as String?,
    );
  }
}

// ─── OrderItem ────────────────────────────────────────────────────────────────

class OrderItem {
  final GarmentType type;
  final int quantity;
  final double price;
  final Map<String, double> measurements;
  final String? fabricDetails;
  final String? notes;
  final List<String> images;

  const OrderItem({
    required this.type,
    required this.quantity,
    required this.price,
    this.measurements = const {},
    this.fabricDetails,
    this.notes,
    this.images = const [],
  });

  double get total => price * quantity;

  OrderItem copyWith({
    GarmentType? type,
    int? quantity,
    double? price,
    Map<String, double>? measurements,
    String? fabricDetails,
    String? notes,
    List<String>? images,
  }) {
    return OrderItem(
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      measurements: measurements ?? this.measurements,
      fabricDetails: fabricDetails ?? this.fabricDetails,
      notes: notes ?? this.notes,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'quantity': quantity,
        'price': price,
        'measurements': measurements,
        'fabricDetails': fabricDetails,
        'notes': notes,
        'images': images,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      type: GarmentType.values.byName(json['type'] as String),
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      measurements: Map<String, double>.from(
        (json['measurements'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      fabricDetails: json['fabricDetails'] as String?,
      notes: json['notes'] as String?,
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

// ─── Order ────────────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String orderNumber;
  final Customer customer;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final String? notes;
  final double advancePaid;
  final List<String> referenceImages;
  final String? completedByTailor;
  final DateTime? completedAt;
  final List<NotificationLog> notifications;
  final List<Payment> payments;
  final bool isUrgent;
  final double urgentCharge;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.items,
    this.status = OrderStatus.pending,
    required this.dueDate,
    required this.createdAt,
    this.notes,
    this.advancePaid = 0,
    this.referenceImages = const [],
    this.completedByTailor,
    this.completedAt,
    this.notifications = const [],
    this.payments = const [],
    this.isUrgent = false,
    this.urgentCharge = 0,
    this.isDeleted = false,
    this.deletedAt,
  });

  String get itemsSummary =>
      items.map((i) => '${i.type.label} ×${i.quantity}').join(', ');

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.total) + urgentCharge;

  double get totalPaid =>
      advancePaid + payments.fold(0.0, (sum, p) => sum + p.amount);

  double get balanceAmount => totalAmount - totalPaid;

  bool get isOverdue =>
      status != OrderStatus.completed &&
      status != OrderStatus.cancelled &&
      dueDate.isBefore(DateTime.now());

  Order copyWith({
    String? id,
    String? orderNumber,
    Customer? customer,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    String? notes,
    double? advancePaid,
    List<String>? referenceImages,
    String? completedByTailor,
    DateTime? completedAt,
    List<NotificationLog>? notifications,
    List<Payment>? payments,
    bool? isUrgent,
    double? urgentCharge,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      advancePaid: advancePaid ?? this.advancePaid,
      referenceImages: referenceImages ?? this.referenceImages,
      completedByTailor: completedByTailor ?? this.completedByTailor,
      completedAt: completedAt ?? this.completedAt,
      notifications: notifications ?? this.notifications,
      payments: payments ?? this.payments,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentCharge: urgentCharge ?? this.urgentCharge,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'customerId': customer.id,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'advancePaid': advancePaid,
        'referenceImages': referenceImages,
        'completedByTailor': completedByTailor,
        'completedAt': completedAt?.toIso8601String(),
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'isUrgent': isUrgent,
        'urgentCharge': urgentCharge,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json, Customer customer) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      customer: customer,
      items: (json['items'] as List)
          .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      status: OrderStatus.values.byName(json['status'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      advancePaid: (json['advancePaid'] as num?)?.toDouble() ?? 0,
      referenceImages: List<String>.from(json['referenceImages'] ?? []),
      completedByTailor: json['completedByTailor'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notifications: (json['notifications'] as List?)
              ?.map((n) =>
                  NotificationLog.fromJson(Map<String, dynamic>.from(n as Map)))
              .toList() ??
          [],
      payments: (json['payments'] as List?)
              ?.map(
                  (p) => Payment.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          [],
      isUrgent: json['isUrgent'] as bool? ?? false,
      urgentCharge: (json['urgentCharge'] as num?)?.toDouble() ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}
