class NoteModel {
  final String id;
  final String subject;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? aiAnalysis;

  final String type; // 'typed' or 'scanned'
  final String organizedText;
  final List<String> keyPoints;
  final String originalImageBase64;
  final String mainTopic;

  NoteModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.aiAnalysis,
    this.type = 'typed',
    this.organizedText = '',
    this.keyPoints = const [],
    this.originalImageBase64 = '',
    this.mainTopic = '',
  });

  factory NoteModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NoteModel(
      id: documentId,
      subject: data['subject'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      aiAnalysis: data['aiAnalysis'],
      type: data['type'] ?? 'typed',
      organizedText: data['organizedText'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      originalImageBase64: data['originalImageBase64'] ?? '',
      mainTopic: data['mainTopic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'aiAnalysis': aiAnalysis,
      'type': type,
      'organizedText': organizedText,
      'keyPoints': keyPoints,
      'originalImageBase64': originalImageBase64,
      'mainTopic': mainTopic,
    };
  }

  NoteModel copyWith({
    String? id,
    String? subject,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? aiAnalysis,
    String? type,
    String? organizedText,
    List<String>? keyPoints,
    String? originalImageBase64,
    String? mainTopic,
  }) {
    return NoteModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      type: type ?? this.type,
      organizedText: organizedText ?? this.organizedText,
      keyPoints: keyPoints ?? this.keyPoints,
      originalImageBase64: originalImageBase64 ?? this.originalImageBase64,
      mainTopic: mainTopic ?? this.mainTopic,
    );
  }
}
