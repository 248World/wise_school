class AttendanceModel {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final String status;
  final String markedBy;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.createdAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Present',
      markedBy: map['markedBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'date': date.toIso8601String(),
      'status': status,
      'markedBy': markedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}