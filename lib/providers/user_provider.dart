import 'package:flutter/material.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  bool isLoading = false;
  List<Map<String, dynamic>> users = [];

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    users = await _databaseService.getUsers();

    isLoading = false;
    notifyListeners();
  }

  Future<String> getUserRole(String userId) async {
    return _databaseService.getUserRole(userId);
  }
}