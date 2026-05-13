class TeacherModel {
  final String id;
  final String userId;
  final List<String> subjectIds;
  final List<String> classIds;
  final String employeeNumber;

  TeacherModel({
    required this.id,
    required this.userId,
    required this.subjectIds,
    required this.classIds,
    required this.employeeNumber,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeacherModel(
      id: documentId,
      userId: map['userId'] ?? '',
      subjectIds: List<String>.from(map['subjectIds'] ?? []),
      classIds: List<String>.from(map['classIds'] ?? []),
      employeeNumber: map['employeeNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subjectIds': subjectIds,
      'classIds': classIds,
      'employeeNumber': employeeNumber,
    };
  }
}