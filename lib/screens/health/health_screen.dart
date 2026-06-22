import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../models/gym_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final isRunning = pomodoro.isRunning;
    final mode = pomodoro.mode;

    String timerString() {
      int minutes = pomodoro.secondsRemaining ~/ 60;
      int seconds = pomodoro.secondsRemaining % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    double progress() {
      int total = mode == PomodoroMode.focus ? PomodoroProvider.focusDuration : PomodoroProvider.breakDuration;
      return 1 - (pomodoro.secondsRemaining / total);
    }

    Color themeColor = mode == PomodoroMode.focus ? context.colors.primary : Colors.green;
    String modeText = mode == PomodoroMode.focus ? (isRunning ? 'FOCUSING' : 'READY') : (isRunning ? 'BREAK TIME' : 'BREAK');

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Focus & Health',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              SizedBox(height: 8),
              Text(
                'Balance your mental productivity with physical well-being.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 48),

              // Pomodoro Timer
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: isRunning 
                            ? themeColor.withOpacity(0.3) 
                            : Colors.black.withOpacity(0.2),
                        blurRadius: isRunning ? 30 : 15,
                        spreadRadius: isRunning ? 10 : 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 230,
                        height: 230,
                        child: CircularProgressIndicator(
                          value: progress(),
                          strokeWidth: 8,
                          backgroundColor: context.colors.background,
                          color: themeColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timerString(),
                            style: TextStyle(
                              color: context.colors.textMain,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            modeText,
                            style: TextStyle(
                              color: isRunning ? themeColor : context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(target: isRunning ? 1 : 0).shimmer(duration: 2.seconds, color: themeColor.withOpacity(0.2)),
              ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
              
              SizedBox(height: 40),

              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRunning)
                    _buildControlButton(
                      icon: Icons.play_arrow_rounded,
                      label: mode == PomodoroMode.focus ? 'Start Focus' : 'Start Break',
                      color: context.colors.success,
                      onPressed: () => context.read<PomodoroProvider>().startTimer(context),
                    )
                  else
                    _buildControlButton(
                      icon: Icons.pause_rounded,
                      label: 'Pause',
                      color: context.colors.accent,
                      onPressed: () => context.read<PomodoroProvider>().pauseTimer(),
                    ),
                  SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.stop_rounded,
                    label: 'Reset',
                    color: context.colors.error,
                    onPressed: () {
                      if (isRunning) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: context.colors.surface,
                            title: const Text('Reset Timer?'),
                            content: const Text('Are you sure you want to reset the current session?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<PomodoroProvider>().resetTimer();
                                  Navigator.pop(ctx);
                                },
                                child: Text('Reset', style: TextStyle(color: context.colors.error)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        context.read<PomodoroProvider>().resetTimer();
                      }
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 56),

              // Gym & Health Section
              Text(
                'Physical Health',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 800.ms),
              SizedBox(height: 16),
              
              GestureDetector(
                onTap: () => _showGymBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2CB67D).withOpacity(0.2),
                        const Color(0xFF2CB67D).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2CB67D).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CB67D).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF2CB67D), size: 36),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log Gym Session',
                              style: TextStyle(
                                color: context.colors.textMain,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed a workout? Log it now to earn a massive +50 XP bonus!',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showGymBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GymLoggerSheet(),
    );
  }
}

class GymLoggerSheet extends StatefulWidget {
  const GymLoggerSheet({super.key});

  @override
  State<GymLoggerSheet> createState() => _GymLoggerSheetState();
}

class _GymLoggerSheetState extends State<GymLoggerSheet> {
  final List<String> types = ['Strength', 'Cardio', 'Flexibility', 'Sports'];
  String selectedType = 'Strength';
  double duration = 45;
  final TextEditingController _notesController = TextEditingController();

  Future<void> _logSession() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final session = GymSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      durationMinutes: duration.toInt(),
      notes: _notesController.text,
      date: DateTime.now(),
    );

    // Save to Firestore
    await FirestoreService().saveGymSession(user.uid, session);

    // Add XP
    context.read<UserProvider>().addXP(50);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Workout Logged! +50 XP 💪 Health is Wealth!'),
        backgroundColor: context.colors.accent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Workout', style: TextStyle(color: context.colors.textMain, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Text('Workout Type', style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((t) {
              final isSelected = t == selectedType;
              return ChoiceChip(
                label: Text(t),
                selected: isSelected,
                selectedColor: context.colors.primary.withOpacity(0.2),
                backgroundColor: context.colors.background,
                labelStyle: TextStyle(color: isSelected ? context.colors.primary : context.colors.textMain),
                onSelected: (val) {
                  if (val) setState(() => selectedType = t);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Text('Duration: ${duration.toInt()} min', style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
          Slider(
            value: duration,
            min: 15,
            max: 120,
            divisions: 7,
            activeColor: context.colors.primary,
            inactiveColor: context.colors.background,
            onChanged: (val) => setState(() => duration = val),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: TextStyle(color: context.colors.textMain),
            decoration: InputDecoration(
              hintText: 'Notes (Optional)',
              hintStyle: TextStyle(color: context.colors.textSecondary),
              filled: true,
              fillColor: context.colors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _logSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Log Session (+50 XP)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
