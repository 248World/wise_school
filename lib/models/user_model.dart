class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String profileImage;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Student',
      profileImage: map['profileImage'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}