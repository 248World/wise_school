import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  String? selectedRole;

  Future<bool> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      selectedRole = role;
      notifyListeners();

      await _authService.login(
        email: email,
        password: password,
      );

      isLoading = false;
      notifyListeners();

      return true;
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString();
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

      await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      isLoading = false;
      notifyListeners();

      return true;
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString();
      notifyListeners();

      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    selectedRole = null;
    notifyListeners();
  }
}