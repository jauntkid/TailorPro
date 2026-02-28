import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a store that can be shared between multiple users.
/// Data (orders, customers, templates, settings) is scoped per store.
class Store {
  final String id;
  final String name;
  final String ownerId;
  final String ownerEmail;
  final List<String> allowedEmails; // emails allowed to access this store
  final DateTime createdAt;

  const Store({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerEmail,
    this.allowedEmails = const [],
    required this.createdAt,
  });

  Store copyWith({
    String? name,
    List<String>? allowedEmails,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      allowedEmails: allowedEmails ?? this.allowedEmails,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'allowedEmails': allowedEmails,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      ownerEmail: json['ownerEmail'] as String? ?? '',
      allowedEmails: List<String>.from(json['allowedEmails'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  bool isOwner(String uid) => ownerId == uid;

  bool isAllowed(String email) {
    final lower = email.toLowerCase();
    return ownerEmail.toLowerCase() == lower ||
        allowedEmails.any((e) => e.toLowerCase() == lower);
  }
}
