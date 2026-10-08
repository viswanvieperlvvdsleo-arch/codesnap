import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/supabase_data_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin =>
      _currentUser?.email.toLowerCase().contains('admin') == true;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      // 1. Check Supabase session first
      final supaUser = SupabaseService.currentUser;
      if (supaUser != null) {
        final profile = await SupabaseDataService.getCurrentUserProfile();
        if (profile != null) {
          final skillList = (profile['skills'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

          final displayName = profile['full_name'] ??
              supaUser.email?.split('@').first ??
              'Developer';
          final username =
              profile['username'] ?? supaUser.email?.split('@').first ?? 'dev';

          _currentUser = User(
            id: supaUser.id,
            name: displayName,
            email: supaUser.email ?? '',
            avatarUrl: profile['avatar_url'] ?? '',
            section: username,
            headline: profile['headline'] ?? '',
            bio: profile['bio'] ?? '',
            department: profile['department'] ?? '',
            location: profile['location'] ?? '',
            skills: skillList,
          );
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // A cached display profile is not an authenticated Supabase session.
      // Treating it as one makes writes fail foreign-key and RLS checks.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      _currentUser = null;
    } catch (e) {
      debugPrint("Error loading session: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In with real Supabase authentication
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    try {
      final res = await SupabaseDataService.signIn(
          email: cleanEmail, password: cleanPassword);
      if (res.user != null && res.session != null) {
        final profile = await SupabaseDataService.getCurrentUserProfile();
        final skillList = (profile?['skills'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        final displayName =
            profile?['full_name'] ?? cleanEmail.split('@').first;
        final username = profile?['username'] ?? cleanEmail.split('@').first;

        _currentUser = User(
          id: res.user!.id,
          name: displayName,
          email: res.user!.email ?? cleanEmail,
          avatarUrl: profile?['avatar_url'] ?? '',
          section: username,
          headline: profile?['headline'] ?? '',
          bio: profile?['bio'] ?? '',
          department: profile?['department'] ?? '',
          location: profile?['location'] ?? '',
          skills: skillList,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'current_user', jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }
      if (res.user != null && res.session == null) {
        _currentUser = null;
        _errorMessage =
            'Registration succeeded. Confirm your email, then sign in.';
      }
    } catch (e) {
      debugPrint("Supabase sign-in exception: $e");
      final errorStr = e.toString().toLowerCase();

      // Never create a fake local session: it cannot satisfy Supabase RLS or
      // the profiles foreign key and makes successful-looking posts disappear.
      if (errorStr.contains('clientexception') ||
          errorStr.contains('failed to fetch')) {
        _currentUser = null;
        _errorMessage =
            'Cannot reach Supabase. Check your connection and try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // An unconfirmed account has no valid session and must not be treated as
      // authenticated.
      if (errorStr.contains('email not confirmed') ||
          errorStr.contains('email_not_confirmed')) {
        _currentUser = null;
        _isLoading = false;
        _errorMessage =
            'Confirm your email using the Supabase message, then sign in.';
        notifyListeners();
        return false;
      }

      // If invalid credentials or user not registered, return informative error
      if (errorStr.contains('invalid login credentials') ||
          errorStr.contains('invalid_credentials')) {
        _errorMessage =
            'Invalid email or password. If you are new, please click "Register" below.';
      } else {
        _errorMessage = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign Up with real Supabase authentication
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim();
    final cleanUsername = username.trim().toLowerCase();
    final displayName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : username.trim();

    try {
      final res = await SupabaseDataService.signUp(
        email: cleanEmail,
        password: password,
        username: cleanUsername,
        fullName: displayName,
      );

      if (res.user != null) {
        _currentUser = User(
          id: res.user!.id,
          name: displayName,
          email: cleanEmail,
          avatarUrl: '',
          section: cleanUsername,
          headline: '',
          bio: '',
          department: '',
          location: '',
          skills: const [],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'current_user', jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Supabase sign-up error: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('user already registered') ||
          errorStr.contains('already exists')) {
        // Automatically log them in with the supplied credentials!
        final loginOk = await login(cleanEmail, password);
        if (loginOk) return true;
        _errorMessage =
            'An account with this email already exists. Please login.';
      } else {
        _errorMessage = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Unconfirmed users cannot receive an authenticated Supabase session.
  Future<bool> loginWithUnconfirmedEmail(String email) async {
    _isLoading = true;
    _currentUser = null;
    _errorMessage =
        'Confirm your email using the Supabase message, then sign in.';
    notifyListeners();
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Update Profile details and persist directly to Supabase DB + local cache
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? headline,
    String? bio,
    String? department,
    String? location,
    List<String>? skills,
  }) async {
    if (_currentUser == null) return;

    // 1. Persist to Supabase Database
    final persistedAvatar = await SupabaseDataService.updateProfile(
      fullName: name,
      avatarUrl: avatarUrl,
      headline: headline,
      bio: bio,
      department: department,
      location: location,
      skills: skills,
    );

    // 2. Update local state
    _currentUser = User(
      id: _currentUser!.id,
      name: name ?? _currentUser!.name,
      email: _currentUser!.email,
      section: _currentUser!.section,
      avatarUrl: persistedAvatar ?? _currentUser!.avatarUrl,
      headline: headline ?? _currentUser!.headline,
      bio: bio ?? _currentUser!.bio,
      department: department ?? _currentUser!.department,
      location: location ?? _currentUser!.location,
      skills: skills ?? _currentUser!.skills,
      bannerUrl: _currentUser!.bannerUrl,
    );

    // 3. Cache to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    } catch (e) {
      debugPrint("Error saving updated profile to cache: $e");
    }

    notifyListeners();
  }

  /// Sign Out and purge cache completely
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseDataService.signOut();
    } catch (_) {}

    _currentUser = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
