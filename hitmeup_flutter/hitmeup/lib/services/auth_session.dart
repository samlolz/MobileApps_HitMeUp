import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static const String _storageKey = 'hitmeup_current_user';
  static final AuthSession instance = AuthSession._();

  Map<String, dynamic>? _currentUser;
  bool _isLoaded = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoaded => _isLoaded;
  bool get isLoggedIn => _currentUser != null;

  int? get userId {
    final value = _currentUser?['id'];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? get userName => _currentUser?['name'] as String?;
  String? get userEmail => _currentUser?['email'] as String?;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      _currentUser = null;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _currentUser = decoded;
      } else {
        _currentUser = null;
      }
    } catch (_) {
      _currentUser = null;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _currentUser = Map<String, dynamic>.from(user);
    _isLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_currentUser));
    notifyListeners();
  }

  Future<void> clear() async {
    _currentUser = null;
    _isLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
