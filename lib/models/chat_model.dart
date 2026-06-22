import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatSession {
  final String id;
  final String subject;
  String title;
  DateTime lastUpdated;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.subject,
    required this.title,
    required this.lastUpdated,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'title': title,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map, String id) {
    return ChatSession(
      id: id,
      subject: map['subject'] ?? 'General',
      title: map['title'] ?? 'New Chat',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messages: List<ChatMessage>.from(
        (map['messages'] as List<dynamic>? ?? []).map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
      ),
    );
  }
}
