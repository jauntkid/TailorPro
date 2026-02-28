import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/customer.dart';
import '../models/order.dart';
import 'whatsapp_service.dart';
import 'storage_service.dart';

/// Data service backed by Cloud Firestore for persistent cloud storage.
/// Data is loaded into memory on init for fast, synchronous reads.
/// Writes update memory first (instant UI), then fire Firestore writes in the
/// background. Firestore SDK handles offline caching and automatic retry.
class DataService extends ChangeNotifier {
  final FirebaseFirestore _db;
  final String storeId;

  // Firestore references — store-scoped under stores/{storeId}/
  late final CollectionReference _customersCol;
  late final CollectionReference _ordersCol;
  late final CollectionReference _templatesCol;
  late final DocumentReference _settingsDoc;

  DataService({required this.storeId, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    final storeDoc = _db.collection('stores').doc(storeId);
    _customersCol = storeDoc.collection('customers');
    _ordersCol = storeDoc.collection('orders');
    _templatesCol = storeDoc.collection('templates');
    _settingsDoc = storeDoc.collection('settings').doc('app');
  }

  // In-memory data
  final List<Customer> _customers = [];
  final List<Order> _orders = [];
  final List<MeasurementTemplate> _templates = [];
  int _nextCustomerNum = 100;
  int _nextOrderNum = 6;
  int _nextPaymentNum = 1;
  ThemeMode _themeMode = ThemeMode.dark;
  final WhatsAppService _whatsApp = WhatsAppService.instance;

  // Pagination state
  static const int _orderPageSize = 50;
  DocumentSnapshot? _lastOrderDoc;
  bool _hasMoreOrders = true;
  bool _isLoadingMore = false;
  bool get hasMoreOrders => _hasMoreOrders;
  bool get isLoadingMore => _isLoadingMore;

  // Real-time listener subscriptions
  StreamSubscription? _customersSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _templatesSub;
  StreamSubscription? _settingsSub;
  bool _customersListenerInit = false;
  bool _ordersListenerInit = false;
  bool _templatesListenerInit = false;
  bool _settingsListenerInit = false;

  // Shop details (for billing)
  String _shopName = 'Godukaan';
  String _shopAddress = '';
  String _shopPhone = '';
  String _shopGstin = '';
  String _shopUpi = '';
  List<String> _garmentTypes = [
    'Shirt',
    'Trouser',
    'Suit',
    'Sherwani',
    'Kurta',
    'Blouse',
    'Lehenga',
    'Saree Blouse',
    'Dress',
  ];
  Map<String, double> _garmentDefaults = {
    'Shirt': 500,
    'Trouser': 400,
    'Suit': 3500,
    'Sherwani': 5000,
    'Kurta': 600,
    'Blouse': 450,
    'Lehenga': 8000,
    'Saree Blouse': 500,
    'Dress': 1500,
  };
  Map<String, List<String>> _garmentMeasurements = {
    'Shirt': ['Chest', 'Shoulder', 'Sleeve Length', 'Shirt Length', 'Neck'],
    'Trouser': ['Waist', 'Hip', 'Inseam', 'Outseam'],
    'Suit': [
      'Chest',
      'Shoulder',
      'Sleeve Length',
      'Jacket Length',
      'Waist',
      'Hip'
    ],
    'Sherwani': [
      'Chest',
      'Shoulder',
      'Sleeve Length',
      'Sherwani Length',
      'Neck'
    ],
    'Kurta': ['Chest', 'Shoulder', 'Sleeve Length', 'Kurta Length', 'Neck'],
    'Blouse': ['Bust', 'Shoulder', 'Sleeve Length', 'Blouse Length'],
    'Lehenga': ['Waist', 'Hip', 'Lehenga Length'],
    'Saree Blouse': ['Bust', 'Shoulder', 'Sleeve Length', 'Blouse Length'],
    'Dress': ['Bust', 'Waist', 'Hip', 'Dress Length', 'Shoulder'],
  };
  String _measurementUnit = 'inches';

  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopPhone => _shopPhone;
  String get shopGstin => _shopGstin;
  String get shopUpi => _shopUpi;
  List<String> get garmentTypes => List.unmodifiable(_garmentTypes);
  Map<String, double> get garmentDefaults => Map.unmodifiable(_garmentDefaults);
  Map<String, List<String>> get garmentMeasurements =>
      Map.unmodifiable(_garmentMeasurements);
  String get measurementUnit => _measurementUnit;

  /// Get measurement fields for a specific item type.
  List<String> getMeasurementFields(String itemType) {
    return _garmentMeasurements[itemType] ??
        ['Custom 1', 'Custom 2', 'Custom 3'];
  }

  void updateGarmentMeasurements(String name, List<String> fields) {
    _garmentMeasurements[name] = List.from(fields);
    _persistSettings();
    notifyListeners();
  }

  void updateMeasurementUnit(String unit) {
    _measurementUnit = unit;
    _persistSettings();
    notifyListeners();
  }

  void updateShopDetails({
    String? name,
    String? address,
    String? phone,
    String? gstin,
    String? upi,
  }) {
    if (name != null) _shopName = name;
    if (address != null) _shopAddress = address;
    if (phone != null) _shopPhone = phone;
    if (gstin != null) _shopGstin = gstin;
    if (upi != null) _shopUpi = upi;
    _persistSettings();
    notifyListeners();
  }

  void updateGarmentTypes(List<String> types) {
    _garmentTypes = List.from(types);
    // Remove defaults for deleted types, keep existing prices
    _garmentDefaults.removeWhere((k, _) => !types.contains(k));
    _garmentMeasurements.removeWhere((k, _) => !types.contains(k));
    for (final t in types) {
      _garmentDefaults.putIfAbsent(t, () => 0);
      _garmentMeasurements.putIfAbsent(
          t, () => ['Custom 1', 'Custom 2', 'Custom 3']);
    }
    _persistSettings();
    notifyListeners();
  }

  void updateGarmentDefault(String name, double price) {
    _garmentDefaults[name] = price;
    _persistSettings();
    notifyListeners();
  }

  void renameGarmentType(String oldName, String newName) {
    final idx = _garmentTypes.indexOf(oldName);
    if (idx == -1) return;
    final price = _garmentDefaults.remove(oldName) ?? 0;
    final measurements = _garmentMeasurements.remove(oldName);
    _garmentTypes[idx] = newName;
    _garmentDefaults[newName] = price;
    if (measurements != null) _garmentMeasurements[newName] = measurements;
    _persistSettings();
    notifyListeners();
  }

  // ─── Initialization ───────────────────────────────────────────────────

  /// Must be called (and awaited) before the app starts.
  Future<void> init() async {
    await _loadData();
    _startListeners();
  }

  @override
  void dispose() {
    _customersSub?.cancel();
    _ordersSub?.cancel();
    _templatesSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load settings
      final settingsSnap = await _settingsDoc.get();
      if (settingsSnap.exists) {
        final data = settingsSnap.data() as Map<String, dynamic>;
        _themeMode = ThemeMode.values[data['themeMode'] as int? ?? 2];
        _nextCustomerNum = data['nextCustomerNum'] as int? ?? 100;
        _nextOrderNum = data['nextOrderNum'] as int? ?? 6;
        _nextPaymentNum = data['nextPaymentNum'] as int? ?? 1;
        _shopName = data['shopName'] as String? ?? 'Godukaan';
        _shopAddress = data['shopAddress'] as String? ?? '';
        _shopPhone = data['shopPhone'] as String? ?? '';
        _shopGstin = data['shopGstin'] as String? ?? '';
        _shopUpi = data['shopUpi'] as String? ?? '';
        if (data['garmentTypes'] != null) {
          _garmentTypes = List<String>.from(data['garmentTypes'] as List);
        }
        if (data['garmentDefaults'] != null) {
          _garmentDefaults = (data['garmentDefaults'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
        if (data['garmentMeasurements'] != null) {
          _garmentMeasurements =
              (data['garmentMeasurements'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
        }
        _measurementUnit = data['measurementUnit'] as String? ?? 'inches';
      }

      // Load customers
      final custSnap = await _customersCol.get();
      _customers.clear();
      for (final doc in custSnap.docs) {
        _customers.add(Customer.fromJson(doc.data() as Map<String, dynamic>));
      }

      // Load orders — first page (customers must be loaded first)
      _orders.clear();
      _lastOrderDoc = null;
      _hasMoreOrders = true;
      final ordQuery = _ordersCol
          .orderBy('createdAt', descending: true)
          .limit(_orderPageSize);
      final ordSnap = await ordQuery.get();
      for (final doc in ordSnap.docs) {
        final map = doc.data() as Map<String, dynamic>;
        final customerId = map['customerId'] as String;
        final customer = _customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => Customer(
            id: customerId,
            name: 'Unknown',
            phone: '',
            createdAt: DateTime.now(),
          ),
        );
        _orders.add(Order.fromJson(map, customer));
      }
      if (ordSnap.docs.isNotEmpty) {
        _lastOrderDoc = ordSnap.docs.last;
      }
      _hasMoreOrders = ordSnap.docs.length == _orderPageSize;

      // Load measurement templates
      final tmplSnap = await _templatesCol.get();
      _templates.clear();
      for (final doc in tmplSnap.docs) {
        _templates.add(
            MeasurementTemplate.fromJson(doc.data() as Map<String, dynamic>));
      }
    } catch (e) {
      debugPrint('Error loading from Firestore: $e');
    }
  }

  // ─── Real-time Firestore Listeners ────────────────────────────────────

  /// Attach snapshot listeners for multi-device real-time sync.
  /// Called after initial `.get()` load so first emission is skipped.
  void _startListeners() {
    // Customers listener
    _customersSub = _customersCol.snapshots().listen((snapshot) {
      if (!_customersListenerInit) {
        _customersListenerInit = true;
        return;
      }
      bool changed = false;
      for (final change in snapshot.docChanges) {
        if (change.doc.metadata.hasPendingWrites) continue; // skip local writes
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
            final cust = Customer.fromJson(data);
            if (!_customers.any((c) => c.id == cust.id)) {
              _customers.insert(0, cust);
              changed = true;
            }
            break;
          case DocumentChangeType.modified:
            final cust = Customer.fromJson(data);
            final idx = _customers.indexWhere((c) => c.id == cust.id);
            if (idx != -1) {
              _customers[idx] = cust;
              changed = true;
            }
            break;
          case DocumentChangeType.removed:
            _customers.removeWhere((c) => c.id == data['id']);
            changed = true;
            break;
        }
      }
      if (changed) notifyListeners();
    });

    // Orders listener (recent page — for multi-device sync)
    _ordersSub = _ordersCol
        .orderBy('createdAt', descending: true)
        .limit(_orderPageSize)
        .snapshots()
        .listen((snapshot) {
      if (!_ordersListenerInit) {
        _ordersListenerInit = true;
        return;
      }
      bool changed = false;
      for (final change in snapshot.docChanges) {
        if (change.doc.metadata.hasPendingWrites) continue;
        final map = change.doc.data() as Map<String, dynamic>;
        final customerId = map['customerId'] as String;
        final customer = _customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => Customer(
            id: customerId,
            name: 'Unknown',
            phone: '',
            createdAt: DateTime.now(),
          ),
        );
        switch (change.type) {
          case DocumentChangeType.added:
            final order = Order.fromJson(map, customer);
            if (!_orders.any((o) => o.id == order.id)) {
              _orders.insert(0, order);
              changed = true;
            }
            break;
          case DocumentChangeType.modified:
            final order = Order.fromJson(map, customer);
            final idx = _orders.indexWhere((o) => o.id == order.id);
            if (idx != -1) {
              _orders[idx] = order;
              changed = true;
            }
            break;
          case DocumentChangeType.removed:
            _orders.removeWhere((o) => o.id == map['id']);
            changed = true;
            break;
        }
      }
      if (changed) notifyListeners();
    });

    // Templates listener
    _templatesSub = _templatesCol.snapshots().listen((snapshot) {
      if (!_templatesListenerInit) {
        _templatesListenerInit = true;
        return;
      }
      bool changed = false;
      for (final change in snapshot.docChanges) {
        if (change.doc.metadata.hasPendingWrites) continue;
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
            final tmpl = MeasurementTemplate.fromJson(data);
            if (!_templates.any((t) => t.id == tmpl.id)) {
              _templates.insert(0, tmpl);
              changed = true;
            }
            break;
          case DocumentChangeType.modified:
            final tmpl = MeasurementTemplate.fromJson(data);
            final idx = _templates.indexWhere((t) => t.id == tmpl.id);
            if (idx != -1) {
              _templates[idx] = tmpl;
              changed = true;
            }
            break;
          case DocumentChangeType.removed:
            _templates.removeWhere((t) => t.id == data['id']);
            changed = true;
            break;
        }
      }
      if (changed) notifyListeners();
    });

    // Settings listener
    _settingsSub = _settingsDoc.snapshots().listen((snapshot) {
      if (!_settingsListenerInit) {
        _settingsListenerInit = true;
        return;
      }
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _themeMode = ThemeMode.values[data['themeMode'] as int? ?? 2];
        _shopName = data['shopName'] as String? ?? 'Godukaan';
        _shopAddress = data['shopAddress'] as String? ?? '';
        _shopPhone = data['shopPhone'] as String? ?? '';
        _shopGstin = data['shopGstin'] as String? ?? '';
        _shopUpi = data['shopUpi'] as String? ?? '';
        if (data['garmentTypes'] != null) {
          _garmentTypes = List<String>.from(data['garmentTypes'] as List);
        }
        if (data['garmentDefaults'] != null) {
          _garmentDefaults = (data['garmentDefaults'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
        if (data['garmentMeasurements'] != null) {
          _garmentMeasurements =
              (data['garmentMeasurements'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
        }
        _measurementUnit = data['measurementUnit'] as String? ?? 'inches';
        notifyListeners();
      }
    });
  }

  /// Load next page of orders from Firestore.
  Future<void> loadMoreOrders() async {
    if (!_hasMoreOrders || _isLoadingMore || _lastOrderDoc == null) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = _ordersCol
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastOrderDoc!)
          .limit(_orderPageSize);
      final snap = await query.get();

      for (final doc in snap.docs) {
        final map = doc.data() as Map<String, dynamic>;
        final customerId = map['customerId'] as String;
        final customer = _customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => Customer(
            id: customerId,
            name: 'Unknown',
            phone: '',
            createdAt: DateTime.now(),
          ),
        );
        // Avoid duplicates
        if (!_orders.any((o) => o.id == map['id'])) {
          _orders.add(Order.fromJson(map, customer));
        }
      }

      if (snap.docs.isNotEmpty) {
        _lastOrderDoc = snap.docs.last;
      }
      _hasMoreOrders = snap.docs.length == _orderPageSize;
    } catch (e) {
      debugPrint('Error loading more orders: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Write settings/counters to Firestore (fire-and-forget).
  void _persistSettings() {
    _settingsDoc.set(_settingsJson());
  }

  Map<String, dynamic> _settingsJson() => {
        'themeMode': _themeMode.index,
        'nextCustomerNum': _nextCustomerNum,
        'nextOrderNum': _nextOrderNum,
        'nextPaymentNum': _nextPaymentNum,
        'shopName': _shopName,
        'shopAddress': _shopAddress,
        'shopPhone': _shopPhone,
        'shopGstin': _shopGstin,
        'shopUpi': _shopUpi,
        'garmentTypes': _garmentTypes,
        'garmentDefaults': _garmentDefaults,
        'garmentMeasurements': _garmentMeasurements.map(
          (k, v) => MapEntry(k, v),
        ),
        'measurementUnit': _measurementUnit,
      };

  // ─── Theme ────────────────────────────────────────────────────────────

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _persistSettings();
    notifyListeners();
  }

  // ─── Customers ────────────────────────────────────────────────────────

  List<Customer> getCustomers({String? search}) {
    var list = _customers.where((c) => !c.isDeleted).toList();
    if (search == null || search.isEmpty) {
      return List.unmodifiable(list);
    }
    final q = search.toLowerCase();
    return list
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Customer? getCustomerById(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Customer addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) {
    final customer = Customer(
      id: 'cust_${_nextCustomerNum++}',
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _customers.insert(0, customer);

    // Firestore writes (fire-and-forget)
    _customersCol.doc(customer.id).set(customer.toJson());
    _persistSettings();

    notifyListeners();
    return customer;
  }

  void updateCustomer(Customer updated) {
    final index = _customers.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _customers[index] = updated;
      _customersCol.doc(updated.id).set(updated.toJson());

      // Update in-memory customer reference in related orders.
      // Orders store customerId in Firestore, so no order doc update needed.
      for (var i = 0; i < _orders.length; i++) {
        if (_orders[i].customer.id == updated.id) {
          _orders[i] = _orders[i].copyWith(customer: updated);
        }
      }
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      _customersCol.doc(id).set(_customers[index].toJson());
    }

    // Soft-delete associated templates
    final templateIds =
        _templates.where((t) => t.customerId == id).map((t) => t.id).toList();
    _templates.removeWhere((t) => t.customerId == id);
    for (final tid in templateIds) {
      _templatesCol.doc(tid).delete();
    }

    notifyListeners();
  }

  // ─── Clear All Data ───────────────────────────────────────────────────

  /// Delete ALL customers, orders, templates, and reset counters.
  /// This wipes the store's data from both memory and Firestore.
  Future<void> clearAllData() async {
    // Delete all documents from Firestore
    final batch = _db.batch();
    for (final c in _customers) {
      batch.delete(_customersCol.doc(c.id));
    }
    for (final o in _orders) {
      batch.delete(_ordersCol.doc(o.id));
    }
    for (final t in _templates) {
      batch.delete(_templatesCol.doc(t.id));
    }
    await batch.commit();

    // Clear in-memory data
    _customers.clear();
    _orders.clear();
    _templates.clear();
    _nextCustomerNum = 100;
    _nextOrderNum = 1;
    _nextPaymentNum = 1;
    _lastOrderDoc = null;
    _hasMoreOrders = true;

    _persistSettings();
    notifyListeners();
  }

  // ─── Orders ───────────────────────────────────────────────────────────

  List<Order> getOrders({
    OrderStatus? status,
    String? customerId,
    String? search,
  }) {
    var orders = _orders.where((o) => !o.isDeleted).toList();
    if (status != null) {
      orders = orders.where((o) => o.status == status).toList();
    }
    if (customerId != null) {
      orders = orders.where((o) => o.customer.id == customerId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      orders = orders
          .where((o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.customer.name.toLowerCase().contains(q) ||
              o.itemsSummary.toLowerCase().contains(q) ||
              (o.notes?.toLowerCase().contains(q) ?? false) ||
              o.totalAmount.toStringAsFixed(0).contains(q) ||
              (o.completedByTailor?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    // Sort: urgent first, then by creation date (newest first)
    orders.sort((a, b) {
      if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return orders;
  }

  Order? getOrderById(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Order addOrder({
    required Customer customer,
    required List<OrderItem> items,
    required DateTime dueDate,
    String? notes,
    double advancePaid = 0,
    List<String> referenceImages = const [],
    bool isUrgent = false,
    double urgentCharge = 0,
  }) {
    final order = Order(
      id: 'ord_$_nextOrderNum',
      orderNumber: 'ORD-${_nextOrderNum.toString().padLeft(5, '0')}',
      customer: customer,
      items: items,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      notes: notes,
      advancePaid: advancePaid,
      referenceImages: referenceImages,
      isUrgent: isUrgent,
      urgentCharge: urgentCharge,
    );
    _nextOrderNum++;
    _orders.insert(0, order);

    _ordersCol.doc(order.id).set(order.toJson());
    _persistSettings();

    // Upload reference images to Firebase Storage in background
    if (referenceImages.isNotEmpty) {
      _uploadOrderImages(order.id, order.orderNumber, referenceImages);
    }

    // Auto-save measurement templates for each item with measurements
    for (final item in items) {
      if (item.measurements.isNotEmpty) {
        saveTemplate(
          customerId: customer.id,
          garmentType: item.type,
          label: item.type.label,
          measurements: item.measurements,
          orderNumber: order.orderNumber,
        );
      }
    }

    notifyListeners();
    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus status,
      {String? tailorName}) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: status,
        completedByTailor: status == OrderStatus.completed
            ? tailorName
            : _orders[index].completedByTailor,
        completedAt: status == OrderStatus.completed ? DateTime.now() : null,
      );
      _ordersCol.doc(orderId).set(_orders[index].toJson());
      notifyListeners();
    }
  }

  void updateOrder(
    String orderId, {
    List<OrderItem>? items,
    DateTime? dueDate,
    String? notes,
    double? advancePaid,
    List<String>? referenceImages,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        items: items,
        dueDate: dueDate,
        notes: notes,
        advancePaid: advancePaid,
        referenceImages: referenceImages,
      );
      _ordersCol.doc(orderId).set(_orders[index].toJson());
      notifyListeners();
    }
  }

  void deleteOrder(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      _ordersCol.doc(id).set(_orders[index].toJson());
      notifyListeners();
    }
  }

  /// Upload reference images to Firebase Storage in the background.
  /// Updates the order with cloud URLs once complete.
  Future<void> _uploadOrderImages(
      String orderId, String orderNumber, List<String> localPaths) async {
    try {
      final urls = await StorageService.instance
          .uploadImages(localPaths, folder: 'orders/$orderNumber');
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(referenceImages: urls);
        _ordersCol.doc(orderId).set(_orders[index].toJson());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Background image upload failed: $e');
    }
  }

  // ─── Payments ─────────────────────────────────────────────────────────

  void addPayment(
    String orderId, {
    required double amount,
    required String method,
    String? notes,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final payment = Payment(
        id: 'pay_${_nextPaymentNum++}',
        amount: amount,
        date: DateTime.now(),
        method: method,
        notes: notes,
      );
      _orders[index] = _orders[index].copyWith(
        payments: [..._orders[index].payments, payment],
      );
      _ordersCol.doc(orderId).set(_orders[index].toJson());
      _persistSettings();
      notifyListeners();
    }
  }

  // ─── Measurement Templates ────────────────────────────────────────────

  List<MeasurementTemplate> getTemplates({
    String? customerId,
    GarmentType? garmentType,
  }) {
    var templates = _templates.toList();
    if (customerId != null) {
      templates = templates.where((t) => t.customerId == customerId).toList();
    }
    if (garmentType != null) {
      templates = templates.where((t) => t.garmentType == garmentType).toList();
    }
    return templates;
  }

  MeasurementTemplate saveTemplate({
    required String customerId,
    required GarmentType garmentType,
    required String label,
    required Map<String, double> measurements,
    String? orderNumber,
  }) {
    // Check if template already exists for this customer + garment type
    final existingIdx = _templates.indexWhere(
        (t) => t.customerId == customerId && t.garmentType == garmentType);

    if (existingIdx != -1) {
      // Update existing template — archive old measurements to history
      final existing = _templates[existingIdx];
      final snapshot = MeasurementSnapshot(
        measurements: Map.from(existing.measurements),
        recordedAt: DateTime.now(),
        orderNumber: orderNumber,
      );
      final updated = existing.copyWith(
        measurements: measurements,
        history: [...existing.history, snapshot],
      );
      _templates[existingIdx] = updated;
      _templatesCol.doc(updated.id).set(updated.toJson());
      notifyListeners();
      return updated;
    }

    final template = MeasurementTemplate(
      id: 'tmpl_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      garmentType: garmentType,
      label: label,
      measurements: measurements,
      createdAt: DateTime.now(),
      history: [
        MeasurementSnapshot(
          measurements: Map.from(measurements),
          recordedAt: DateTime.now(),
          orderNumber: orderNumber,
        ),
      ],
    );
    _templates.insert(0, template);
    _templatesCol.doc(template.id).set(template.toJson());
    notifyListeners();
    return template;
  }

  void deleteTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    _templatesCol.doc(id).delete();
    notifyListeners();
  }

  // ─── WhatsApp Notifications ───────────────────────────────────────────

  Future<NotificationLog> sendWhatsAppNotification(
      String orderId, WhatsAppNotificationType type) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return NotificationLog(
          type: type, sentAt: DateTime.now(), message: '', delivered: false);
    }
    final order = _orders[index];
    final log = await _whatsApp.sendNotification(
        order: order, type: type, shopUpi: _shopUpi);
    _orders[index] = order.copyWith(
      notifications: [...order.notifications, log],
    );
    _ordersCol.doc(orderId).set(_orders[index].toJson());
    notifyListeners();
    return log;
  }

  // ─── Stats ────────────────────────────────────────────────────────────

  int get totalOrders => _orders.where((o) => !o.isDeleted).length;
  int get totalCustomers => _customers.where((c) => !c.isDeleted).length;

  /// Direct read-only access to in-memory lists (for dashboards).
  List<Order> get orders =>
      List.unmodifiable(_orders.where((o) => !o.isDeleted));
  List<Customer> get customers =>
      List.unmodifiable(_customers.where((c) => !c.isDeleted));

  Map<OrderStatus, int> getOrderStats() {
    final active = _orders.where((o) => !o.isDeleted);
    final stats = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      stats[status] = active.where((o) => o.status == status).length;
    }
    return stats;
  }

  int getOrderCountForCustomer(String customerId) {
    return _orders
        .where((o) => !o.isDeleted && o.customer.id == customerId)
        .length;
  }

  double getTotalRevenueForCustomer(String customerId) {
    return _orders
        .where((o) => !o.isDeleted && o.customer.id == customerId)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  // ─── Dashboard Helpers ────────────────────────────────────────────────

  List<Order> get overdueOrders {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            !o.isDeleted &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled &&
            o.dueDate.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Order> get dueTodayOrders {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return _orders
        .where((o) =>
            !o.isDeleted &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled &&
            !o.dueDate.isBefore(todayStart) &&
            o.dueDate.isBefore(todayEnd))
        .toList();
  }

  List<Order> get upcomingOrders {
    final now = DateTime.now();
    final tomorrowStart =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final weekEnd = tomorrowStart.add(const Duration(days: 7));
    return _orders
        .where((o) =>
            !o.isDeleted &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled &&
            !o.dueDate.isBefore(tomorrowStart) &&
            o.dueDate.isBefore(weekEnd))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Order> get inProgressOrders {
    return _orders
        .where((o) => !o.isDeleted && o.status == OrderStatus.inProgress)
        .toList();
  }

  List<Order> get recentlyCompleted {
    return _orders
        .where((o) => !o.isDeleted && o.status == OrderStatus.completed)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt)
          .compareTo(a.completedAt ?? a.createdAt));
  }

  // ─── Daily Report ─────────────────────────────────────────────────────

  Map<String, dynamic> getDailyReport() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayOrders =
        _orders.where((o) => !o.isDeleted && !o.createdAt.isBefore(todayStart));
    final todayCompleted = _orders.where((o) =>
        !o.isDeleted &&
        o.status == OrderStatus.completed &&
        o.completedAt != null &&
        !o.completedAt!.isBefore(todayStart));
    final todayRevenue =
        todayOrders.fold(0.0, (double sum, o) => sum + o.advancePaid);
    final totalPendingAmount = _orders
        .where((o) =>
            !o.isDeleted &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .fold(0.0, (double sum, o) => sum + o.balanceAmount);
    final overdue = _orders.where((o) =>
        !o.isDeleted &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled &&
        o.dueDate.isBefore(now));
    return {
      'todayNewOrders': todayOrders.length,
      'todayCompleted': todayCompleted.length,
      'todayRevenue': todayRevenue,
      'totalPendingAmount': totalPendingAmount,
      'overdueCount': overdue.length,
      'totalRevenue': _orders
          .where((o) => !o.isDeleted)
          .fold(0.0, (double sum, o) => sum + o.totalPaid),
    };
  }

  // ─── Global Search ────────────────────────────────────────────────────

  Map<String, List<dynamic>> globalSearch(String query) {
    if (query.isEmpty) return {'orders': [], 'customers': []};
    final q = query.toLowerCase();
    final matchedOrders = _orders
        .where((o) =>
            !o.isDeleted &&
            (o.orderNumber.toLowerCase().contains(q) ||
                o.customer.name.toLowerCase().contains(q) ||
                o.itemsSummary.toLowerCase().contains(q) ||
                (o.notes?.toLowerCase().contains(q) ?? false) ||
                o.totalAmount.toStringAsFixed(0).contains(q) ||
                o.balanceAmount.toStringAsFixed(0).contains(q) ||
                (o.completedByTailor?.toLowerCase().contains(q) ?? false) ||
                o.status.label.toLowerCase().contains(q)))
        .toList();
    final matchedCustomers = _customers
        .where((c) =>
            !c.isDeleted &&
            (c.name.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                (c.email?.toLowerCase().contains(q) ?? false) ||
                (c.address?.toLowerCase().contains(q) ?? false)))
        .toList();
    return {'orders': matchedOrders, 'customers': matchedCustomers};
  }

  /// Mock AI image search — simulates LLM-powered search.
  Future<List<Order>> searchByImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return _orders
        .where((o) =>
            !o.isDeleted &&
            (o.referenceImages.isNotEmpty ||
                o.items.any((item) => item.fabricDetails != null)))
        .take(3)
        .toList();
  }

  // ─── Seed Sample Data ─────────────────────────────────────────────────

  void _seedData() {
    final rajesh = Customer(
      id: 'cust_1',
      name: 'Rajesh Kumar',
      phone: '+91 98765 43210',
      email: 'rajesh@email.com',
      address: '15, MG Road, Bangalore',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    );
    final priya = Customer(
      id: 'cust_2',
      name: 'Priya Sharma',
      phone: '+91 87654 32109',
      email: 'priya.sharma@email.com',
      address: '42, Park Street, Mumbai',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    final amit = Customer(
      id: 'cust_3',
      name: 'Amit Patel',
      phone: '+91 76543 21098',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    final anitha = Customer(
      id: 'cust_4',
      name: 'Anitha Reddy',
      phone: '+91 65432 10987',
      email: 'anitha@email.com',
      address: '8, Jubilee Hills, Hyderabad',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );
    final mohammed = Customer(
      id: 'cust_5',
      name: 'Mohammed Ali',
      phone: '+91 54321 09876',
      address: '23, Charminar Road, Hyderabad',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    _customers.addAll([rajesh, priya, amit, anitha, mohammed]);

    _orders.addAll([
      Order(
        id: 'ord_1',
        orderNumber: 'ORD-00001',
        customer: rajesh,
        items: [
          const OrderItem(
            type: GarmentType.shirt,
            quantity: 2,
            price: 1500,
            measurements: {
              'Chest': 42,
              'Shoulder': 18,
              'Sleeve Length': 25,
              'Shirt Length': 30,
              'Neck': 16,
            },
            fabricDetails: 'White cotton, slim fit',
          ),
          const OrderItem(
            type: GarmentType.trouser,
            quantity: 1,
            price: 1200,
            measurements: {
              'Waist': 34,
              'Hip': 40,
              'Inseam': 30,
              'Outseam': 42,
            },
          ),
        ],
        status: OrderStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        advancePaid: 2000,
        notes: 'Customer prefers slim fit',
        referenceImages: ['assets/images/sample_shirt.jpg'],
      ),
      Order(
        id: 'ord_2',
        orderNumber: 'ORD-00002',
        customer: priya,
        items: [
          const OrderItem(
            type: GarmentType.suit,
            quantity: 1,
            price: 8500,
            measurements: {
              'Chest': 38,
              'Shoulder': 16,
              'Sleeve Length': 23,
              'Jacket Length': 26,
              'Waist': 30,
              'Hip': 38,
            },
            fabricDetails: 'Navy blue wool blend',
          ),
        ],
        status: OrderStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        advancePaid: 3000,
      ),
      Order(
        id: 'ord_3',
        orderNumber: 'ORD-00003',
        customer: rajesh,
        items: [
          const OrderItem(
            type: GarmentType.sherwani,
            quantity: 1,
            price: 12000,
            measurements: {
              'Chest': 42,
              'Shoulder': 18,
              'Sleeve Length': 25,
              'Sherwani Length': 42,
              'Neck': 16,
            },
            fabricDetails: 'Maroon silk with gold embroidery',
          ),
        ],
        status: OrderStatus.readyForTrial,
        dueDate: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        advancePaid: 6000,
        notes: 'For wedding — needs perfect fit',
        referenceImages: [
          'assets/images/sample_sherwani.jpg',
          'assets/images/sample_embroidery.jpg',
        ],
      ),
      Order(
        id: 'ord_4',
        orderNumber: 'ORD-00004',
        customer: anitha,
        items: [
          const OrderItem(
            type: GarmentType.blouse,
            quantity: 3,
            price: 800,
            measurements: {
              'Bust': 36,
              'Shoulder': 14,
              'Sleeve Length': 12,
              'Blouse Length': 15,
            },
            fabricDetails: 'Silk, different colours',
          ),
        ],
        status: OrderStatus.completed,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        advancePaid: 2400,
        completedByTailor: 'Raju',
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Order(
        id: 'ord_5',
        orderNumber: 'ORD-00005',
        customer: mohammed,
        items: [
          const OrderItem(
            type: GarmentType.kurta,
            quantity: 2,
            price: 1800,
            measurements: {
              'Chest': 44,
              'Shoulder': 19,
              'Sleeve Length': 26,
              'Kurta Length': 38,
              'Neck': 17,
            },
          ),
          const OrderItem(
            type: GarmentType.trouser,
            quantity: 2,
            price: 1000,
            measurements: {
              'Waist': 36,
              'Hip': 42,
              'Inseam': 31,
              'Outseam': 43,
            },
          ),
        ],
        status: OrderStatus.pending,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        advancePaid: 1000,
        notes: 'Eid collection — festive wear',
      ),
    ]);

    // Seed a measurement template
    _templates.add(MeasurementTemplate(
      id: 'tmpl_1',
      customerId: 'cust_1',
      garmentType: GarmentType.shirt,
      label: 'Rajesh - Standard Shirt',
      measurements: {
        'Chest': 42,
        'Shoulder': 18,
        'Sleeve Length': 25,
        'Shirt Length': 30,
        'Neck': 16,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ));
  }

  // ─── Analytics helpers ──────────────────────────────────────────────

  /// Revenue grouped by day for the last [days] days.
  List<MapEntry<DateTime, double>> getRevenueByDay(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final map = <DateTime, double>{};
    for (var d = start;
        !d.isAfter(DateTime(now.year, now.month, now.day));
        d = d.add(const Duration(days: 1))) {
      map[d] = 0;
    }
    for (final o in _orders) {
      if (o.isDeleted) continue;
      if (o.status == OrderStatus.completed) {
        final revenueDate = o.completedAt ?? o.createdAt;
        final day =
            DateTime(revenueDate.year, revenueDate.month, revenueDate.day);
        if (map.containsKey(day)) {
          map[day] = map[day]! + o.totalAmount;
        }
      }
    }
    return map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Orders created per day for the last [days] days.
  List<MapEntry<DateTime, int>> getOrdersByDay(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final map = <DateTime, int>{};
    for (var d = start;
        !d.isAfter(DateTime(now.year, now.month, now.day));
        d = d.add(const Duration(days: 1))) {
      map[d] = 0;
    }
    for (final o in _orders) {
      if (o.isDeleted) continue;
      final day =
          DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (map.containsKey(day)) {
        map[day] = map[day]! + 1;
      }
    }
    return map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Top customers by total spent.
  List<MapEntry<Customer, double>> getTopCustomers({int limit = 5}) {
    final totals = <String, double>{};
    for (final o in _orders) {
      if (o.isDeleted) continue;
      totals[o.customer.id] = (totals[o.customer.id] ?? 0) + o.totalAmount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) {
      final cust = _customers.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Customer(
          id: e.key,
          name: 'Unknown',
          phone: '',
          createdAt: DateTime.now(),
        ),
      );
      return MapEntry(cust, e.value);
    }).toList();
  }

  /// Items count grouped by garment type (across all non-deleted orders).
  Map<String, int> getItemsByType() {
    final counts = <String, int>{};
    for (final o in _orders) {
      if (o.isDeleted) continue;
      for (final item in o.items) {
        counts[item.type.label] =
            (counts[item.type.label] ?? 0) + item.quantity;
      }
    }
    return counts;
  }

  /// Average turnaround time in days (created → completed) for completed orders.
  double getAvgTurnaroundDays() {
    final completed = _orders.where((o) =>
        !o.isDeleted &&
        o.status == OrderStatus.completed &&
        o.completedAt != null);
    if (completed.isEmpty) return 0;
    final totalDays = completed.fold(
        0.0,
        (sum, o) =>
            sum + o.completedAt!.difference(o.createdAt).inHours / 24.0);
    return totalDays / completed.length;
  }

  /// Payment collection rate (totalPaid / totalAmount) across active orders.
  double getCollectionRate() {
    final activeOrders =
        _orders.where((o) => !o.isDeleted && o.status != OrderStatus.cancelled);
    if (activeOrders.isEmpty) return 0;
    final totalAmount = activeOrders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalPaid = activeOrders.fold(0.0, (s, o) => s + o.totalPaid);
    if (totalAmount == 0) return 0;
    return totalPaid / totalAmount;
  }

  /// Monthly revenue for last [months] months.
  List<MapEntry<String, double>> getMonthlyRevenue({int months = 6}) {
    final now = DateTime.now();
    final result = <MapEntry<String, double>>[];
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      double revenue = 0;
      for (final o in _orders) {
        if (o.isDeleted) continue;
        if (o.status == OrderStatus.completed) {
          final revenueDate = o.completedAt ?? o.createdAt;
          if (!revenueDate.isBefore(month) && revenueDate.isBefore(nextMonth)) {
            revenue += o.totalAmount;
          }
        }
      }
      final label =
          '${_monthNames[month.month - 1]}${month.year != now.year ? ' ${month.year % 100}' : ''}';
      result.add(MapEntry(label, revenue));
    }
    return result;
  }

  static const _monthNames = [
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

  /// Busiest days of the week (order count per weekday).
  Map<String, int> getBusiestDays() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = {for (final d in dayNames) d: 0};
    for (final o in _orders) {
      if (o.isDeleted) continue;
      counts[dayNames[o.createdAt.weekday - 1]] =
          counts[dayNames[o.createdAt.weekday - 1]]! + 1;
    }
    return counts;
  }
}
