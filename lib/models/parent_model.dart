class ParentModel {
  final String id;
  final String userId;
  final List<String> childIds;

  ParentModel({
    required this.id,
    required this.userId,
    required this.childIds,
  });

  factory ParentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ParentModel(
      id: documentId,
      userId: map['userId'] ?? '',
      childIds: List<String>.from(map['childIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'childIds': childIds,
    };
  }
}