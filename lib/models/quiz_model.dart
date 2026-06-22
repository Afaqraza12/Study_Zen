class QuizModel {
  final String id;
  final String subject;
  final int score;
  final int totalQuestions;
  final DateTime takenAt;

  QuizModel({
    required this.id,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.takenAt,
  });

  factory QuizModel.fromMap(Map<String, dynamic> data, String documentId) {
    return QuizModel(
      id: documentId,
      subject: data['subject'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      takenAt: data['takenAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'score': score,
      'totalQuestions': totalQuestions,
      'takenAt': takenAt,
    };
  }

  QuizModel copyWith({
    String? id,
    String? subject,
    int? score,
    int? totalQuestions,
    DateTime? takenAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}
