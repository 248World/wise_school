import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return 'Student';
    }

    final data = doc.data();

    return data?['role'] ?? 'Student';
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Student',
        'profileImage': data['profileImage'] ?? '',
        'isActive': data['isActive'] ?? true,
        'createdAt': data['createdAt'],
      };
    }).toList();
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }

  Future<void> saveAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    final batch = _firestore.batch();

    for (final item in attendanceData) {
      final docRef = _firestore.collection('attendance').doc();

      batch.set(docRef, {
        ...item,
        'classId': classId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> saveMarks({
    required String classId,
    required String subjectId,
    required List<Map<String, dynamic>> marksData,
  }) async {
    final batch = _firestore.batch();

    for (final item in marksData) {
      final docRef = _firestore.collection('marks').doc();

      batch.set(docRef, {
        ...item,
        'classId': classId,
        'subjectId': subjectId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}