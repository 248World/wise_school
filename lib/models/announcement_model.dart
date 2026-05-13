class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String targetRole;
  final String createdBy;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.targetRole,
    required this.createdBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AnnouncementModel(
      id: documentId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      targetRole: map['targetRole'] ?? 'All',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'targetRole': targetRole,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}