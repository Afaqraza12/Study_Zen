import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> fetchUser(String uid) async {
    _user = await _firestoreService.getUser(uid);
    notifyListeners();
    
    // Automatically check and update streak on fetch
    if (_user != null) {
      await checkAndUpdateStreak();
      // Update last login timestamp
      await _firestoreService.updateLastLogin(uid);
    }
  }

  Future<void> updateProfile(String newName, String newPhotoUrl) async {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        name: newName,
        photoUrl: newPhotoUrl,
        joinedDate: _user!.joinedDate,
        subjects: _user!.subjects,
        lastLogin: _user!.lastLogin,
        streak: _user!.streak,
        pomodoroSessions: _user!.pomodoroSessions,
        xp: _user!.xp,
        level: _user!.level,
      );
      await _firestoreService.updateUserNameAndPhoto(_user!.uid, newName, newPhotoUrl);
      notifyListeners();
    }
  }

  Future<void> updateSubjects(List<String> subjects) async {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        name: _user!.name,
        photoUrl: _user!.photoUrl,
        joinedDate: _user!.joinedDate,
        subjects: subjects,
        lastLogin: _user!.lastLogin,
        streak: _user!.streak,
        pomodoroSessions: _user!.pomodoroSessions,
        xp: _user!.xp,
        level: _user!.level,
      );
      await _firestoreService.updateUserSubjects(_user!.uid, subjects);
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  Future<void> addXP(int amount) async {
    if (_user == null) return;

    int newXP = _user!.xp + amount;
    
    // Custom Level Calculation
    int newLevel = 1;
    if (newXP >= 4000) newLevel = 8;
    else if (newXP >= 2500) newLevel = 7;
    else if (newXP >= 1500) newLevel = 6;
    else if (newXP >= 900) newLevel = 5;
    else if (newXP >= 500) newLevel = 4;
    else if (newXP >= 250) newLevel = 3;
    else if (newXP >= 100) newLevel = 2;

    // Create updated user
    final updatedUser = _user!.copyWith(
      xp: newXP,
      level: newLevel,
    );

    // Update local state
    _user = updatedUser;
    notifyListeners();

    // Update Firestore
    await _firestoreService.updateUserXP(updatedUser.uid, newXP, newLevel);
  }

  Future<void> removeXP(int amount) async {
    if (_user == null) return;

    int newXP = _user!.xp - amount;
    if (newXP < 0) newXP = 0;
    
    // Custom Level Calculation
    int newLevel = 1;
    if (newXP >= 4000) newLevel = 8;
    else if (newXP >= 2500) newLevel = 7;
    else if (newXP >= 1500) newLevel = 6;
    else if (newXP >= 900) newLevel = 5;
    else if (newXP >= 500) newLevel = 4;
    else if (newXP >= 250) newLevel = 3;
    else if (newXP >= 100) newLevel = 2;

    final updatedUser = _user!.copyWith(xp: newXP, level: newLevel);
    _user = updatedUser;
    notifyListeners();
    await _firestoreService.updateUserXP(updatedUser.uid, newXP, newLevel);
  }

  Future<void> incrementPomodoro() async {
    if (_user == null) return;
    final updatedUser = _user!.copyWith(pomodoroSessions: _user!.pomodoroSessions + 1);
    _user = updatedUser;
    notifyListeners();
    await _firestoreService.updatePomodoroCount(updatedUser.uid, updatedUser.pomodoroSessions);
  }

  Future<void> checkAndUpdateStreak() async {
    if (_user == null) return;

    final now = DateTime.now();
    final lastLogin = _user!.lastLogin;
    
    // Strip time for strict day comparison
    final today = DateTime(now.year, now.month, now.day);
    final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    
    final difference = today.difference(lastLoginDay).inDays;
    
    int newStreak = _user!.streak;
    
    if (difference == 1) {
      // Logged in the next consecutive day
      newStreak += 1;
    } else if (difference > 1) {
      // Missed a day, reset streak
      newStreak = 1; // Actually, the prompt says "reset to 0", let's fix it.
      if (today.difference(lastLoginDay).inDays > 1) {
          newStreak = 0;
      }
    } else {
      // Logged in on the same day, no streak change
      return;
    }

    // Award +15 XP for daily login (once per calendar day)
    if (difference >= 1) {
      addXP(15);
    }

    final updatedUser = _user!.copyWith(streak: newStreak);
    _user = updatedUser;
    notifyListeners();

    await _firestoreService.updateUserStreak(updatedUser.uid, newStreak);
  }
}
