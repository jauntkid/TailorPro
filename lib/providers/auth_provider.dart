import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  final ApiService _apiService = ApiService();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    _isAuthenticated = token != null;

    // If authenticated, try to fetch user data
    if (_isAuthenticated) {
      try {
        // Call API endpoint to validate the token and get updated user data
        final result = await _apiService.getCurrentUser();
        if (result['success'] && result['data'] != null) {
          _userData = result['data'];

          // Store the basic user data in SharedPreferences as backup
          await _storeUserDataLocally(result['data']);
        } else {
          // Try to load cached user data while showing an error
          _tryLoadCachedUserData();

          print('Error fetching user data: ${result['error']}');
          // If the token is invalid, clear it
          await clearToken();
          _isAuthenticated = false;
        }
      } catch (e) {
        // Try to load cached user data in case of network errors
        _tryLoadCachedUserData();

        print('Error validating token: $e');
        // If there's an error, keep auth state but show warning on next API call
        _isAuthenticated = token != null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  // Try to load user data from SharedPreferences as a fallback
  Future<void> _tryLoadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');
      final String? userEmail = prefs.getString('user_email');
      final String? userRole = prefs.getString('user_role');

      if (userId != null && userName != null) {
        _userData = {
          '_id': userId,
          'name': userName,
          'email': userEmail,
          'role': userRole,
        };
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }

  // Store basic user info in SharedPreferences
  Future<void> _storeUserDataLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userData['_id'] != null) {
        await prefs.setString('user_id', userData['_id'].toString());
      }
      if (userData['name'] != null) {
        await prefs.setString('user_name', userData['name'].toString());
      }
      if (userData['email'] != null) {
        await prefs.setString('user_email', userData['email'].toString());
      }
      if (userData['role'] != null) {
        await prefs.setString('user_role', userData['role'].toString());
      }
    } catch (e) {
      print('Error storing user data locally: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      print('Login response: $result');

      if (result['success']) {
        _isAuthenticated = true;

        // If user data is available in the login response
        if (result['data'] != null) {
          _userData = result['data'];

          // Store basic user data for offline access
          await _storeUserDataLocally(result['data']);
        } else {
          // If not, fetch user data separately
          await _fetchUserData();
        }

        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Error during login: $e'};
    }
  }

  // Fetch current user data
  Future<void> _fetchUserData() async {
    try {
      final result = await _apiService.getCurrentUser();
      if (result['success'] && result['data'] != null) {
        _userData = result['data'];

        // Store basic user data for offline access
        await _storeUserDataLocally(result['data']);

        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(userData);
      print('Register response: $result');

      if (result['success']) {
        _isAuthenticated = true;

        // If user data is available in the register response
        if (result['data'] != null) {
          _userData = result['data'];

          // Store basic user data for offline access
          await _storeUserDataLocally(result['data']);
        } else {
          // If not, fetch user data separately
          await _fetchUserData();
        }

        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Error during registration: $e'};
    }
  }

  Future<bool> isLoggedIn() async {
    // Check from shared preferences or any persistent storage
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // If we have a token but no user data, try to fetch it
    if (token != null && _userData == null) {
      await _fetchUserData();
    }

    return token != null;
  }

  Future<Map<String, dynamic>> logout() async {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic> result = {'success': true};

    try {
      result = await _apiService.logout();
    } catch (e) {
      print('Logout error: $e');
      result = {'success': false, 'error': 'Error during logout: $e'};
    }

    // Regardless of API success, clear local data
    _isAuthenticated = false;
    _userData = null;
    await clearToken();

    _isLoading = false;
    notifyListeners();

    return result;
  }

  // Clear the token and user data from SharedPreferences
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }

  // Add a manual reset function for debugging
  Future<void> resetAuth() async {
    await clearToken();
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }
}
