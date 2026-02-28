import 'order.dart';

/// A snapshot of measurements at a point in time.
class MeasurementSnapshot {
  final Map<String, double> measurements;
  final DateTime recordedAt;
  final String? orderNumber; // Which order these measurements came from

  const MeasurementSnapshot({
    required this.measurements,
    required this.recordedAt,
    this.orderNumber,
  });

  Map<String, dynamic> toJson() => {
        'measurements': measurements.map((k, v) => MapEntry(k, v)),
        'recordedAt': recordedAt.toIso8601String(),
        'orderNumber': orderNumber,
      };

  factory MeasurementSnapshot.fromJson(Map<String, dynamic> json) {
    return MeasurementSnapshot(
      measurements: Map<String, double>.from(
        (json['measurements'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      orderNumber: json['orderNumber'] as String?,
    );
  }
}

/// Measurement template — saves a customer's measurements for a garment type
/// so future orders can auto-fill. Includes history of past measurements.
class MeasurementTemplate {
  final String id;
  final String customerId;
  final GarmentType garmentType;
  final String label;
  final Map<String, double> measurements;
  final DateTime createdAt;
  final List<MeasurementSnapshot> history;

  const MeasurementTemplate({
    required this.id,
    required this.customerId,
    required this.garmentType,
    required this.label,
    required this.measurements,
    required this.createdAt,
    this.history = const [],
  });

  MeasurementTemplate copyWith({
    String? label,
    Map<String, double>? measurements,
    List<MeasurementSnapshot>? history,
  }) {
    return MeasurementTemplate(
      id: id,
      customerId: customerId,
      garmentType: garmentType,
      label: label ?? this.label,
      measurements: measurements ?? this.measurements,
      createdAt: createdAt,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'garmentType': garmentType.name,
        'label': label,
        'measurements': measurements,
        'createdAt': createdAt.toIso8601String(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory MeasurementTemplate.fromJson(Map<String, dynamic> json) {
    return MeasurementTemplate(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      garmentType: GarmentType.values.byName(json['garmentType'] as String),
      label: json['label'] as String,
      measurements: Map<String, double>.from(
        (json['measurements'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      history: (json['history'] as List?)
              ?.map((h) => MeasurementSnapshot.fromJson(
                  Map<String, dynamic>.from(h as Map)))
              .toList() ??
          [],
    );
  }
}

/// Customer data model with full JSON serialisation for Hive persistence.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
