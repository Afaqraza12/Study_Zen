class GymSessionModel {
  final String id;
  final String type;
  final int durationMinutes;
  final String? notes;
  final DateTime date;

  GymSessionModel({
    required this.id,
    required this.type,
    required this.durationMinutes,
    this.notes,
    required this.date,
  });

  factory GymSessionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return GymSessionModel(
      id: documentId,
      type: data['type'] ?? 'Strength',
      durationMinutes: data['durationMinutes'] ?? 0,
      notes: data['notes'],
      date: data['date']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'date': date,
    };
  }

  GymSessionModel copyWith({
    String? id,
    String? type,
    int? durationMinutes,
    String? notes,
    DateTime? date,
  }) {
    return GymSessionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}
