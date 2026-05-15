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
        'userName': data['userName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Student',
        'profileImage': data['profileImage'] ?? '',
        'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
        'gender': data['gender'] ?? '',
        'city': data['city'] ?? '',
        'address': data['address'] ?? '',
        'about': data['about'] ?? '',
        'isActive': data['isActive'] ?? true,
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'parentId': data['parentId'] ?? '',
        'parentName': data['parentName'] ?? '',
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getParents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Parent')
        .where('isActive', isEqualTo: true)
        .get();

    final parents = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Parent',
        'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
        'isActive': data['isActive'] ?? true,
        'createdAt': data['createdAt'],
      };
    }).toList();

    parents.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });

    return parents;
  }

  Future<List<Map<String, dynamic>>> getStudentsByParent({
    required String parentId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .get();

    final students = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Student',
        'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'parentId': data['parentId'] ?? '',
        'parentName': data['parentName'] ?? '',
        'isActive': data['isActive'] ?? true,
      };
    }).toList();

    students.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });

    return students;
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData != null && userData['role'] == 'Student') {
      final classId = userData['classId'] ?? '';

      if (classId.toString().isNotEmpty) {
        await recalculateClassStudentCount(classId: classId);
      }
    }
  }

  Future<void> updateStudentClass({
    required String userId,
    required String classId,
    required String className,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final oldUserDoc = await userRef.get();

    String oldClassId = '';

    if (oldUserDoc.exists) {
      final oldData = oldUserDoc.data();
      oldClassId = oldData?['classId'] ?? '';
    }

    await userRef.update({
      'classId': classId,
      'className': className,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (oldClassId.isNotEmpty && oldClassId != classId) {
      await recalculateClassStudentCount(classId: oldClassId);
    }

    await recalculateClassStudentCount(classId: classId);
  }

  Future<void> updateStudentParent({
    required String userId,
    required String parentId,
    required String parentName,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'parentId': parentId,
      'parentName': parentName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recalculateClassStudentCount({
    required String classId,
  }) async {
    if (classId.isEmpty) {
      return;
    }

    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    await _firestore.collection('classes').doc(classId).set(
      {
        'studentCount': studentsSnapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
        'updatedAt': data['updatedAt'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getClassesByTeacher({
    required String teacherName,
  }) async {
    final snapshot = await _firestore
        .collection('classes')
        .where('teacherName', isEqualTo: teacherName)
        .get();

    final classes = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'studentCount': data['studentCount'] ?? 0,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    classes.sort((a, b) {
      return (a['className'] ?? '').toString().compareTo(
            (b['className'] ?? '').toString(),
          );
    });

    return classes;
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClass({
    required String classId,
  }) async {
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('classes').doc(classId));

    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .get();

    for (final studentDoc in studentsSnapshot.docs) {
      batch.update(studentDoc.reference, {
        'classId': '',
        'className': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
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
        'updatedAt': data['updatedAt'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSubjectsByClass({
    required String classId,
  }) async {
    final snapshot = await _firestore
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();

    final subjects = snapshot.docs.map((doc) {
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
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    subjects.sort((a, b) {
      return (a['subjectName'] ?? '').toString().compareTo(
            (b['subjectName'] ?? '').toString(),
          );
    });

    return subjects;
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
      'updatedAt': FieldValue.serverTimestamp(),
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

    final students = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'role': data['role'] ?? 'Student',
        'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'parentId': data['parentId'] ?? '',
        'parentName': data['parentName'] ?? '',
        'isActive': data['isActive'] ?? true,
      };
    }).toList();

    students.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });

    return students;
  }

  Future<void> saveAttendance({
    required String classId,
    required String className,
    required String markedBy,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final item in attendanceData) {
      final studentId = item['studentId'] ?? '';

      if (studentId.toString().isEmpty) {
        continue;
      }

      final docId = '${dateKey}_${classId}_$studentId';
      final docRef = _firestore.collection('attendance').doc(docId);

      batch.set(
        docRef,
        {
          'studentId': studentId,
          'studentName': item['studentName'] ?? '',
          'classId': classId,
          'className': className,
          'status': item['status'] ?? 'Present',
          'markedBy': markedBy,
          'date': now.toIso8601String(),
          'dateKey': dateKey,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
        'dateKey': data['dateKey'] ?? '',
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();
  }

  String gradeFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Pass';
    return 'Weak';
  }

  String progressFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Average';
    return 'Needs Support';
  }

  Future<void> saveMarks({
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required String teacherId,
    required String teacherName,
    required List<Map<String, dynamic>> marksData,
  }) async {
    final batch = _firestore.batch();

    for (final item in marksData) {
      final studentId = item['studentId'] ?? '';

      if (studentId.toString().isEmpty) {
        continue;
      }

      final markValue = item['mark'];

      double mark = 0;

      if (markValue is int) {
        mark = markValue.toDouble();
      } else if (markValue is double) {
        mark = markValue;
      } else {
        mark = double.tryParse(markValue.toString()) ?? 0;
      }

      final coefficientValue = item['coefficient'];

      double coefficient = 1;

      if (coefficientValue is int) {
        coefficient = coefficientValue.toDouble();
      } else if (coefficientValue is double) {
        coefficient = coefficientValue;
      } else {
        coefficient = double.tryParse(coefficientValue.toString()) ?? 1;
      }

      final docId = '${studentId}_$subjectId';
      final docRef = _firestore.collection('marks').doc(docId);

      batch.set(
        docRef,
        {
          'studentId': studentId,
          'studentName': item['studentName'] ?? '',
          'classId': classId,
          'className': className,
          'subjectId': subjectId,
          'subjectName': subjectName,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'mark': mark,
          'grade': item['grade'] ?? gradeFromMark(mark),
          'progress': item['progress'] ?? progressFromMark(mark),
          'comment': item['comment'] ?? '',
          'coefficient': coefficient,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getMarksByStudent({
    required String studentId,
  }) async {
    final snapshot = await _firestore
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    final marks = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'studentId': data['studentId'] ?? '',
        'studentName': data['studentName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'mark': data['mark'] ?? 0,
        'grade': data['grade'] ?? '',
        'progress': data['progress'] ?? '',
        'comment': data['comment'] ?? '',
        'coefficient': data['coefficient'] ?? 1,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    marks.sort((a, b) {
      return (a['subjectName'] ?? '').toString().compareTo(
            (b['subjectName'] ?? '').toString(),
          );
    });

    return marks;
  }

  Future<List<Map<String, dynamic>>> getMarksByClass({
    required String classId,
  }) async {
    final snapshot = await _firestore
        .collection('marks')
        .where('classId', isEqualTo: classId)
        .get();

    final marks = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'studentId': data['studentId'] ?? '',
        'studentName': data['studentName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'mark': data['mark'] ?? 0,
        'grade': data['grade'] ?? '',
        'progress': data['progress'] ?? '',
        'comment': data['comment'] ?? '',
        'coefficient': data['coefficient'] ?? 1,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    marks.sort((a, b) {
      return (a['studentName'] ?? '').toString().compareTo(
            (b['studentName'] ?? '').toString(),
          );
    });

    return marks;
  }
}
