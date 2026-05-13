class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String subjectId;
  final String teacherId;
  final DateTime dueDate;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.dueDate,
    required this.createdAt,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AssignmentModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}