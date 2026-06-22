class TopicModel {
  final String id;
  final String subject;
  final String name;
  final bool isCompleted;

  TopicModel({
    required this.id,
    required this.subject,
    required this.name,
    required this.isCompleted,
  });

  factory TopicModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TopicModel(
      id: documentId,
      subject: data['subject'] ?? '',
      name: data['name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'name': name,
      'isCompleted': isCompleted,
    };
  }

  TopicModel copyWith({
    String? id,
    String? subject,
    String? name,
    bool? isCompleted,
  }) {
    return TopicModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
