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
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
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

  Future<void> updateStudentClass({
    required String userId,
    required String classId,
    required String className,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'classId': classId,
      'className': className,
    });
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    final snapshot = await _firestore
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'studentCount': data['studentCount'] ?? 0,
        'createdAt': data['createdAt'],
      };
    }).toList();
  }

  Future<void> addClass({
    required String className,
    required String level,
    required String teacherId,
    required String teacherName,
  }) async {
    await _firestore.collection('classes').add({
      'className': className.trim(),
      'level': level.trim(),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClass({
    required String classId,
  }) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final snapshot = await _firestore
        .collection('subjects')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'coefficient': data['coefficient'] ?? 1,
        'createdAt': data['createdAt'],
      };
    }).toList();
  }

  Future<void> addSubject({
    required String subjectName,
    required String classId,
    required String className,
    required String teacherId,
    required String teacherName,
    required int coefficient,
  }) async {
    await _firestore.collection('subjects').add({
      'subjectName': subjectName.trim(),
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'coefficient': coefficient,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubject({
    required String subjectId,
  }) async {
    await _firestore.collection('subjects').doc(subjectId).delete();
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass({
    required String classId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Student',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'isActive': data['isActive'] ?? true,
      };
    }).toList();
  }

  Future<void> saveAttendance({
    required String classId,
    required String className,
    required String markedBy,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    final batch = _firestore.batch();

    for (final item in attendanceData) {
      final docRef = _firestore.collection('attendance').doc();

      batch.set(docRef, {
        'studentId': item['studentId'],
        'studentName': item['studentName'],
        'classId': classId,
        'className': className,
        'status': item['status'],
        'markedBy': markedBy,
        'date': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getAttendanceByClass({
    required String classId,
  }) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'studentId': data['studentId'] ?? '',
        'studentName': data['studentName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'status': data['status'] ?? '',
        'markedBy': data['markedBy'] ?? '',
        'date': data['date'] ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();
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