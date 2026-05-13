class ClassModel {
  final String id;
  final String className;
  final String level;
  final String teacherId;
  final int studentCount;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.className,
    required this.level,
    required this.teacherId,
    required this.studentCount,
    required this.createdAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassModel(
      id: documentId,
      className: map['className'] ?? '',
      level: map['level'] ?? '',
      teacherId: map['teacherId'] ?? '',
      studentCount: map['studentCount'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'level': level,
      'teacherId': teacherId,
      'studentCount': studentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}