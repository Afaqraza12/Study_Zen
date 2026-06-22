class SnippetModel {
  final String id;
  final String name;
  final String code;
  final String language;
  final DateTime savedAt;

  SnippetModel({
    required this.id,
    required this.name,
    required this.code,
    required this.language,
    required this.savedAt,
  });

  factory SnippetModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SnippetModel(
      id: documentId,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      language: data['language'] ?? 'C++',
      savedAt: data['savedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'language': language,
      'savedAt': savedAt,
    };
  }

  SnippetModel copyWith({
    String? id,
    String? name,
    String? code,
    String? language,
    DateTime? savedAt,
  }) {
    return SnippetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      language: language ?? this.language,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
