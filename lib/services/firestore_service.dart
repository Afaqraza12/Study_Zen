import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/topic_content_model.dart';
import '../models/topic_model.dart';
import '../models/note_model.dart';
import '../models/quiz_model.dart';
import '../models/snippet_model.dart';
import '../models/gym_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if user exists
  Future<bool> checkUserExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user: $e');
      return false;
    }
  }

  // Create new user
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update last login
  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating login: $e');
    }
  }

  // Update User XP & Level
  Future<void> updateUserXP(String uid, int xp, int level) async {
    try {
      await _db.collection('users').doc(uid).update({
        'xp': xp,
        'level': level,
      });
    } catch (e) {
      print('Error updating XP: $e');
    }
  }

  // Update User Streak
  Future<void> updateUserStreak(String uid, int streak) async {
    try {
      await _db.collection('users').doc(uid).update({
        'streak': streak,
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Update Pomodoro Count
  Future<void> updatePomodoroCount(String uid, int count) async {
    try {
      await _db.collection('users').doc(uid).update({
        'pomodoroSessions': count,
      });
    } catch (e) {
      print('Error updating pomodoro: $e');
    }
  }

  // Get Top Users for Leaderboard
  Stream<List<UserModel>> getTopUsers({int limit = 50}) {
    return _db
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update Profile (Name & Photo)
  Future<void> updateUserNameAndPhoto(String uid, String name, String photoUrl) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Update Subjects
  Future<void> updateUserSubjects(String uid, List<String> subjects) async {
    try {
      await _db.collection('users').doc(uid).update({
        'subjects': subjects,
      });
    } catch (e) {
      print('Error updating subjects: $e');
    }
  }

  // Save Chat Session
  Future<void> saveChatSession(String uid, ChatSession session) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(session.id)
          .set(session.toMap());
    } catch (e) {
      print('Error saving chat: $e');
    }
  }

  // Get User Chat Sessions
  Stream<List<ChatSession>> getUserChatSessions(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatSession.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Delete Chat Session
  Future<void> deleteChatSession(String uid, String chatId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  // Get a specific Chat Session
  Future<ChatSession?> getChatSession(String uid, String chatId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId)
          .get();
      if (doc.exists && doc.data() != null) {
        return ChatSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  // -----------------------------------------------------
  // Topics
  // -----------------------------------------------------
  Stream<List<TopicModel>> getTopics(String uid, String subject) {
    return _db.collection('users').doc(uid).collection('topics')
        .where('subject', isEqualTo: subject)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TopicModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveTopic(String uid, TopicModel topic) async {
    try {
      await _db.collection('users').doc(uid).collection('topics').doc(topic.id).set(topic.toMap());
    } catch (e) {
      print('Error saving topic: $e');
      throw e;
    }
  }

  // Topic Content operations
  Future<TopicContentModel?> getTopicContent(String uid, String topicId) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('topicContent').doc(topicId).get();
      if (doc.exists) {
        return TopicContentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting topic content: $e');
      return null;
    }
  }

  Future<void> saveTopicContent(String uid, String topicId, TopicContentModel content) async {
    try {
      await _db.collection('users').doc(uid).collection('topicContent').doc(topicId).set(content.toMap());
    } catch (e) {
      print('Error saving topic content: $e');
      throw e;
    }
  }

  // -----------------------------------------------------
  // Notes
  // -----------------------------------------------------
  Stream<List<NoteModel>> getNotes(String uid, String subject) {
    return _db.collection('users').doc(uid).collection('notes')
        .where('subject', isEqualTo: subject)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NoteModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveNote(String uid, NoteModel note) async {
    await _db.collection('users').doc(uid).collection('notes').doc(note.id).set(note.toMap());
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _db.collection('users').doc(uid).collection('notes').doc(noteId).delete();
  }

  // -----------------------------------------------------
  // Quizzes
  // -----------------------------------------------------
  Future<void> saveQuizScore(String uid, QuizModel quiz) async {
    await _db.collection('users').doc(uid).collection('quizzes').doc(quiz.id).set(quiz.toMap());
  }

  // -----------------------------------------------------
  // Snippets
  // -----------------------------------------------------
  Future<void> saveSnippet(String uid, SnippetModel snippet) async {
    await _db.collection('users').doc(uid).collection('snippets').doc(snippet.id).set(snippet.toMap());
  }

  // -----------------------------------------------------
  // Gym Sessions
  // -----------------------------------------------------
  Stream<List<GymSessionModel>> getGymSessions(String uid) {
    return _db.collection('users').doc(uid).collection('gym')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GymSessionModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveGymSession(String uid, GymSessionModel session) async {
    await _db.collection('users').doc(uid).collection('gym').doc(session.id).set(session.toMap());
  }
}
