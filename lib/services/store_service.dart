import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/store.dart';

/// Manages store creation, joining, and membership validation.
class StoreService {
  final FirebaseFirestore _db;

  StoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Generate a short random store ID (8 chars, alphanumeric uppercase).
  String _generateStoreId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I,O,0,1
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Look up the store ID for a given user from their user document.
  Future<String?> getUserStoreId(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['storeId'] as String?;
  }

  /// Get a store by its ID.
  Future<Store?> getStore(String storeId) async {
    final doc = await _db.collection('stores').doc(storeId).get();
    if (!doc.exists) return null;
    return Store.fromJson(doc.data()!);
  }

  /// Create a new store. The current user becomes the owner.
  Future<Store> createStore({
    required String uid,
    required String email,
    required String storeName,
  }) async {
    final storeId = _generateStoreId();
    final store = Store(
      id: storeId,
      name: storeName,
      ownerId: uid,
      ownerEmail: email,
      allowedEmails: [],
      createdAt: DateTime.now(),
    );

    // Write store document
    await _db.collection('stores').doc(storeId).set(store.toJson());

    // Link user to store
    await _db.collection('users').doc(uid).set(
      {'storeId': storeId},
      SetOptions(merge: true),
    );

    return store;
  }

  /// Join an existing store by store ID.
  /// Returns the store if the user's email is allowed, else null.
  Future<Store?> joinStore({
    required String storeId,
    required String uid,
    required String email,
  }) async {
    final store = await getStore(storeId);
    if (store == null) return null;

    // Check if user's email is in the allowed list or is the owner
    if (!store.isAllowed(email)) return null;

    // Link user to store
    await _db.collection('users').doc(uid).set(
      {'storeId': storeId},
      SetOptions(merge: true),
    );

    return store;
  }

  /// Add an email to the store's allowed list. Only owner can do this.
  Future<bool> addAllowedEmail({
    required String storeId,
    required String ownerUid,
    required String email,
  }) async {
    final store = await getStore(storeId);
    if (store == null || !store.isOwner(ownerUid)) return false;

    final lower = email.toLowerCase().trim();
    if (store.allowedEmails.any((e) => e.toLowerCase() == lower)) {
      return true; // already exists
    }

    final updated = [...store.allowedEmails, lower];
    await _db.collection('stores').doc(storeId).update({
      'allowedEmails': updated,
    });
    return true;
  }

  /// Remove an email from the store's allowed list.
  Future<bool> removeAllowedEmail({
    required String storeId,
    required String ownerUid,
    required String email,
  }) async {
    final store = await getStore(storeId);
    if (store == null || !store.isOwner(ownerUid)) return false;

    final lower = email.toLowerCase().trim();
    final updated =
        store.allowedEmails.where((e) => e.toLowerCase() != lower).toList();
    await _db.collection('stores').doc(storeId).update({
      'allowedEmails': updated,
    });
    return true;
  }

  /// Disconnect a user from their current store.
  Future<void> leaveStore(String uid) async {
    await _db.collection('users').doc(uid).update({
      'storeId': FieldValue.delete(),
    });
  }
}
