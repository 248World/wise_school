import 'package:flutter/material.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> users = [];

  Future<void> loadUsers() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      users = await _databaseService.getUsers();

      isLoading = false;
      notifyListeners();
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<String> getUserRole(String userId) async {
    return _databaseService.getUserRole(userId);
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _databaseService.updateUserStatus(
        userId: userId,
        isActive: isActive,
      );

      final index = users.indexWhere((user) => user['id'] == userId);

      if (index != -1) {
        users[index]['isActive'] = isActive;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateStudentClass({
    required String userId,
    required String classId,
    required String className,
  }) async {
    try {
      await _databaseService.updateStudentClass(
        userId: userId,
        classId: classId,
        className: className,
      );

      final index = users.indexWhere((user) => user['id'] == userId);

      if (index != -1) {
        users[index]['classId'] = classId;
        users[index]['className'] = className;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateStudentParent({
    required String userId,
    required String parentId,
    required String parentName,
  }) async {
    try {
      await _databaseService.updateStudentParent(
        userId: userId,
        parentId: parentId,
        parentName: parentName,
      );

      final index = users.indexWhere((user) => user['id'] == userId);

      if (index != -1) {
        users[index]['parentId'] = parentId;
        users[index]['parentName'] = parentName;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}