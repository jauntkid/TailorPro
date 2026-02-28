import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class FirebaseAuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;

  FirebaseAuthProvider({required AuthService authService})
      : _authService = authService {
    _init();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _authService.isSignedIn;
  User? get currentUser => _authService.currentUser;

  // Initialize auth state listener
  void _init() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      _userData = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    if (result.success) {
      await _loadUserData();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Sign up failed');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.success) {
      await _loadUserData();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Sign in failed');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      await _loadUserData();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Google sign in failed');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signOut();

    if (result.success) {
      _userData = null;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Sign out failed');
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.resetPassword(email);

    if (result.success) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Password reset failed');
      _setLoading(false);
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? businessName,
    String? address,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.updateProfile(
      name: name,
      phone: phone,
      businessName: businessName,
      address: address,
    );

    if (result.success) {
      await _loadUserData();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Profile update failed');
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
