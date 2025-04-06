class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? referral;
  final String? notes;
  final String profileImage;
  final List<String> measurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.referral,
    this.notes,
    this.profileImage = 'default-customer.jpg',
    this.measurements = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      referral: json['referral'],
      notes: json['notes'],
      profileImage: json['profileImage'] ?? 'default-customer.jpg',
      measurements: List<String>.from(json['measurements'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'referral': referral,
      'notes': notes,
    };
  }
}
