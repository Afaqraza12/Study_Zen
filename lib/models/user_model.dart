class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final List<String> subjects;
  final int level;
  final int xp;
  final int streak;
  final int pomodoroSessions;
  final DateTime lastLogin;
  final DateTime joinedDate;

  String get levelTitle {
    if (xp < 100) return "Novice";         // Level 1: 0-99
    if (xp < 250) return "Student";        // Level 2: 100-249
    if (xp < 500) return "Coder";          // Level 3: 250-499
    if (xp < 900) return "Developer";      // Level 4: 500-899
    if (xp < 1500) return "Engineer";      // Level 5: 900-1499
    if (xp < 2500) return "CS Master";     // Level 6: 1500-2499
    if (xp < 4000) return "Legend";        // Level 7: 2500-3999
    return "CS God";                       // Level 8: 4000+
  }

  int get currentLevelBaseXP {
    if (level == 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 250;
    if (level == 4) return 500;
    if (level == 5) return 900;
    if (level == 6) return 1500;
    if (level == 7) return 2500;
    return 4000;
  }

  int get nextLevelBaseXP {
    if (level == 1) return 100;
    if (level == 2) return 250;
    if (level == 3) return 500;
    if (level == 4) return 900;
    if (level == 5) return 1500;
    if (level == 6) return 2500;
    if (level == 7) return 4000;
    return 4000; // max level
  }

  double get levelProgress {
    if (level >= 8) return 1.0;
    int currentBase = currentLevelBaseXP;
    int nextBase = nextLevelBaseXP;
    if (xp < currentBase) return 0.0;
    return (xp - currentBase) / (nextBase - currentBase);
  }

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.subjects,
    required this.level,
    required this.xp,
    required this.streak,
    required this.pomodoroSessions,
    required this.lastLogin,
    required this.joinedDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photo'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      streak: data['streak'] ?? 0,
      pomodoroSessions: data['pomodoroSessions'] ?? 0,
      lastLogin: data['lastLogin']?.toDate() ?? DateTime.now(),
      joinedDate: data['joinedDate']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photo': photoUrl,
      'subjects': subjects,
      'level': level,
      'xp': xp,
      'streak': streak,
      'pomodoroSessions': pomodoroSessions,
      'lastLogin': lastLogin,
      'joinedDate': joinedDate,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? subjects,
    int? level,
    int? xp,
    int? streak,
    int? pomodoroSessions,
    DateTime? lastLogin,
    DateTime? joinedDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      subjects: subjects ?? this.subjects,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
      lastLogin: lastLogin ?? this.lastLogin,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}
