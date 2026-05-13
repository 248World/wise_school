import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  String? userId;
  String? fullName;
  String? email;
  String? phone;
  String? role;

  bool get isLoggedIn => userId != null;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final userData = await _authService.login(
        email: email,
        password: password,
      );

      userId = userData['id'] ?? '';
      fullName = userData['fullName'] ?? '';
      this.email = userData['email'] ?? '';
      phone = userData['phone'] ?? '';
      role = userData['role'] ?? 'Student';

      isLoading = false;
      notifyListeners();

      return true;
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final userData = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      userId = userData['id'] ?? '';
      this.fullName = userData['fullName'] ?? '';
      this.email = userData['email'] ?? '';
      this.phone = userData['phone'] ?? '';
      this.role = userData['role'] ?? 'Student';

      isLoading = false;
      notifyListeners();

      return true;
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return false;
    }
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordReset(email: email);

      isLoading = false;
      notifyListeners();
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final userData = await _authService.getCurrentUserProfile();

      if (userData != null) {
        userId = userData['id'] ?? '';
        fullName = userData['fullName'] ?? '';
        email = userData['email'] ?? '';
        phone = userData['phone'] ?? '';
        role = userData['role'] ?? 'Student';
      }

      isLoading = false;
      notifyListeners();
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    userId = null;
    fullName = null;
    email = null;
    phone = null;
    role = null;
    errorMessage = null;

    notifyListeners();
  }
}