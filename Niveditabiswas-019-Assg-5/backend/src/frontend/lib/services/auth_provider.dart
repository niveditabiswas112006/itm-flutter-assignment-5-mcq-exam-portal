import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  UserModel? _user;
  bool _isLoading = false;

  AuthProvider({required this.apiService}) {
    _loadSavedUser();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStudent => _user?.isStudent ?? false;
  bool get isLoading => _isLoading;

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      if (userStr != null) {
        final map = json.decode(userStr);
        _user = UserModel.fromJson(map);
        apiService.setUser(_user);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error loading saved user: $e');
    }
  }

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  Future<bool> login({
    required String email,
    required String password,
    String? role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network / Firebase Auth validation
      await Future.delayed(const Duration(milliseconds: 600));

      final inferredRole = role ?? (email.toLowerCase().contains('admin') ? 'admin' : 'student');
      final name = email.split('@').first.replaceAll('.', ' ');
      final formattedName = name.isNotEmpty
          ? '${name[0].toUpperCase()}${name.substring(1)}'
          : 'User';

      final user = UserModel(
        uid: 'usr_${email.hashCode.abs()}',
        email: email,
        name: formattedName,
        role: inferredRole,
        photoUrl: '',
      );

      _user = user;
      apiService.setUser(_user);
      await _persistUser(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final user = UserModel(
        uid: 'usr_${email.hashCode.abs()}',
        email: email,
        name: name,
        role: role,
      );

      _user = user;
      apiService.setUser(_user);
      await _persistUser(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> quickDemoLogin(String role) async {
    _isLoading = true;
    notifyListeners();

    final isAdmin = role.toLowerCase() == 'admin';
    final user = UserModel(
      uid: isAdmin ? 'admin_demo_01' : 'student_demo_01',
      email: isAdmin ? 'admin@itm.edu' : 'student@itm.edu',
      name: isAdmin ? 'Professor Sharma (Admin)' : 'Rahul Kumar (Student)',
      role: isAdmin ? 'admin' : 'student',
      photoUrl: '',
    );

    _user = user;
    apiService.setUser(_user);
    await _persistUser(user);

    _isLoading = false;
    notifyListeners();
  }

  void updateProfilePhoto(String photoUrl) {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        name: _user!.name,
        role: _user!.role,
        photoUrl: photoUrl,
      );
      apiService.setUser(_user);
      _persistUser(_user!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    apiService.setUser(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }
}
