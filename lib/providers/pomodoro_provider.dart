import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

enum PomodoroMode { focus, breakTime }

class PomodoroProvider extends ChangeNotifier {
  static const int focusDuration = 25 * 60;
  static const int breakDuration = 5 * 60;

  int _secondsRemaining = focusDuration;
  bool _isRunning = false;
  PomodoroMode _mode = PomodoroMode.focus;
  Timer? _timer;

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  PomodoroMode get mode => _mode;

  void startTimer(BuildContext context) {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _completeSession(context);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _secondsRemaining = _mode == PomodoroMode.focus ? focusDuration : breakDuration;
    notifyListeners();
  }

  void _completeSession(BuildContext context) {
    _timer?.cancel();
    _isRunning = false;

    if (_mode == PomodoroMode.focus) {
      _mode = PomodoroMode.breakTime;
      _secondsRemaining = breakDuration;
      
      // Award XP
      final userProvider = context.read<UserProvider>();
      userProvider.addXP(25);
      userProvider.incrementPomodoro();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus Session Complete! +25 XP 🔥 Time for a 5 minute break!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      _mode = PomodoroMode.focus;
      _secondsRemaining = focusDuration;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Break Over!'),
          content: const Text('Ready for another focus session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
