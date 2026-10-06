import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/mock_data.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('current_user');
      if (userString != null) {
        _currentUser = User.fromJson(jsonDecode(userString) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple matching in mock data
    final foundUser = MockData.mockUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase().trim(),
      orElse: () => MockData.defaultUser, // Fallback to default user
    );

    _currentUser = foundUser;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(foundUser.toJson()));
    } catch (e) {
      debugPrint("Error saving session: $e");
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }

    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }
}
