class TopicContentModel {
  final String overview;
  final List<String> keyConcepts;
  final String explanation;
  final String codeExample;
  final List<String> commonMistakes;
  final List<String> practiceQuestions;
  final String proTip;

  TopicContentModel({
    required this.overview,
    required this.keyConcepts,
    required this.explanation,
    required this.codeExample,
    required this.commonMistakes,
    required this.practiceQuestions,
    required this.proTip,
  });

  factory TopicContentModel.fromMap(Map<String, dynamic> data) {
    return TopicContentModel(
      overview: data['overview'] ?? '',
      keyConcepts: List<String>.from(data['keyConcepts'] ?? []),
      explanation: data['explanation'] ?? '',
      codeExample: data['codeExample'] ?? '',
      commonMistakes: List<String>.from(data['commonMistakes'] ?? []),
      practiceQuestions: List<String>.from(data['practiceQuestions'] ?? []),
      proTip: data['proTip'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overview': overview,
      'keyConcepts': keyConcepts,
      'explanation': explanation,
      'codeExample': codeExample,
      'commonMistakes': commonMistakes,
      'practiceQuestions': practiceQuestions,
      'proTip': proTip,
    };
  }
}
