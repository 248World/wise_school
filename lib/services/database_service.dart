class DatabaseService {
  Future<String> getUserRole(String userId) async {
    // Later this will read from Firestore users collection.
    await Future.delayed(const Duration(milliseconds: 300));
    return 'Student';
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    // Later this will read users from Firestore.
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {
        'name': 'School Admin',
        'email': 'admin@wiseschool.com',
        'role': 'Admin',
      },
      {
        'name': 'Teacher One',
        'email': 'teacher@wiseschool.com',
        'role': 'Teacher',
      },
      {
        'name': 'Student One',
        'email': 'student@wiseschool.com',
        'role': 'Student',
      },
      {
        'name': 'Parent One',
        'email': 'parent@wiseschool.com',
        'role': 'Parent',
      },
    ];
  }

  Future<void> saveAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    // Later this will save attendance to Firestore.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> saveMarks({
    required String classId,
    required String subjectId,
    required List<Map<String, dynamic>> marksData,
  }) async {
    // Later this will save marks to Firestore.
    await Future.delayed(const Duration(milliseconds: 500));
  }
}