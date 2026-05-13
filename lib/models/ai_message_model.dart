class AIMessageModel {
  final String id;
  final String userId;
  final String role;
  final String prompt;
  final String response;
  final DateTime createdAt;

  AIMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.prompt,
    required this.response,
    required this.createdAt,
  });

  factory AIMessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AIMessageModel(
      id: documentId,
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'Student',
      prompt: map['prompt'] ?? '',
      response: map['response'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'prompt': prompt,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}