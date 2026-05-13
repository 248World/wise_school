class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}