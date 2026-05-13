class StudentModel {
  final String id;
  final String userId;
  final String classId;
  final String parentId;
  final String studentNumber;
  final double attendancePercentage;
  final double averageResult;

  StudentModel({
    required this.id,
    required this.userId,
    required this.classId,
    required this.parentId,
    required this.studentNumber,
    required this.attendancePercentage,
    required this.averageResult,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      id: documentId,
      userId: map['userId'] ?? '',
      classId: map['classId'] ?? '',
      parentId: map['parentId'] ?? '',
      studentNumber: map['studentNumber'] ?? '',
      attendancePercentage:
          (map['attendancePercentage'] ?? 0).toDouble(),
      averageResult: (map['averageResult'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classId': classId,
      'parentId': parentId,
      'studentNumber': studentNumber,
      'attendancePercentage': attendancePercentage,
      'averageResult': averageResult,
    };
  }
}