class MarkModel {
  final String id;
  final String studentId;
  final String subjectId;
  final String teacherId;
  final double mark;
  final String grade;
  final String comment;
  final DateTime createdAt;

  MarkModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.mark,
    required this.grade,
    required this.comment,
    required this.createdAt,
  });

  factory MarkModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MarkModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      mark: (map['mark'] ?? 0).toDouble(),
      grade: map['grade'] ?? '',
      comment: map['comment'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'mark': mark,
      'grade': grade,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}