import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../home/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final bool isEditing;
  const SubjectSelectionScreen({super.key, this.isEditing = false});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final List<String> _suggestedSubjects = [
    'C++', 'DSA', 'COAL', 'OS', 'Web Engineering', 'DSAA Analysis',
    'History', 'Geography', 'Literature', 'Psychology', 'Economics', 'Philosophy',
  ];
  final Set<String> _selectedSubjects = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = context.read<UserProvider>().user;
        if (user != null) {
          setState(() {
            _selectedSubjects.addAll(user.subjects);
          });
        }
      });
    }
  }

  void _handleContinue() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one subject.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing) {
        await context.read<UserProvider>().updateSubjects(_selectedSubjects.toList());
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        final authService = Provider.of<AuthService>(context, listen: false);
        final firestoreService = FirestoreService();
        final user = authService.currentUser;

        if (user != null) {
          // Fetch current user model and update subjects
          final userModel = await firestoreService.getUser(user.uid);
          UserModel updatedUser;
          
          if (userModel != null) {
            updatedUser = userModel.copyWith(subjects: _selectedSubjects.toList());
          } else {
            // Create new user model
            updatedUser = UserModel(
              uid: user.uid,
              name: user.displayName ?? 'Student',
              email: user.email ?? '',
              photoUrl: user.photoURL ?? '',
              subjects: _selectedSubjects.toList(),
              level: 1,
              xp: 0,
              pomodoroSessions: 0,
              streak: 0,
              lastLogin: DateTime.now(),
              joinedDate: DateTime.now(),
            );
          }
          
          await firestoreService.createUser(updatedUser); 
          if (mounted) {
            await context.read<UserProvider>().fetchUser(user.uid);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Error saving subjects: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Subjects'),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you studying?',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              SizedBox(height: 16),
              Text(
                widget.isEditing ? 'Update your subjects to get personalized help.' : 'Choose the subjects you need help with.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _suggestedSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = _suggestedSubjects[index];
                    final isSelected = _selectedSubjects.contains(subject);
                    return InkWell(
                      onTap: () => _toggleSubject(subject),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? context.colors.primary : context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? context.colors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            subject,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : context.colors.textMain,
                                ),
                          ),
                        ),
                      ),
                    ).animate().scale(delay: Duration(milliseconds: 100 * index));
                  },
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final TextEditingController controller = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.colors.surface,
                        title: Text('Add Custom Subject'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Machine Learning',
                          ),
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                setState(() {
                                  _suggestedSubjects.add(controller.text.trim());
                                  _selectedSubjects.add(controller.text.trim());
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Add Custom Subject'),
                ),
              ).animate().fadeIn(delay: 600.ms),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  child: _isLoading
                      ? SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Continue to Dashboard'),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
