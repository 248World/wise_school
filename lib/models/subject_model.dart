class SubjectModel {
  final String id;
  final String subjectName;
  final String classId;
  final String teacherId;
  final int coefficient;

  SubjectModel({
    required this.id,
    required this.subjectName,
    required this.classId,
    required this.teacherId,
    required this.coefficient,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectModel(
      id: documentId,
      subjectName: map['subjectName'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      coefficient: map['coefficient'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'classId': classId,
      'teacherId': teacherId,
      'coefficient': coefficient,
    };
  }
}