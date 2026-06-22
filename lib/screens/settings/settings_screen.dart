import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../auth/onboarding_screen.dart';
import '../auth/subject_selection_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  void _signOut(BuildContext context) async {
    final authService = AuthService();
    final userProvider = context.read<UserProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    await authService.signOut();
    userProvider.clearUser();
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage(BuildContext context, String currentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200, // Heavily compress
        maxHeight: 200,
        imageQuality: 50,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final base64Url = 'data:image/jpeg;base64,$base64String';

        if (context.mounted) {
          await context.read<UserProvider>().updateProfile(currentName, base64Url);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _editName(BuildContext context, String currentName, String currentPhoto) async {
    final TextEditingController controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Edit Name', style: TextStyle(color: context.colors.textMain)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.colors.textMain),
          decoration: InputDecoration(
            hintText: 'Enter your new name',
            hintStyle: TextStyle(color: context.colors.textSecondary.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.textSecondary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.primary)),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              Navigator.pop(context, val.isNotEmpty ? val : null);
            },
            child: Text('Save', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName && context.mounted) {
      await context.read<UserProvider>().updateProfile(newName, currentPhoto);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Name updated successfully!'), backgroundColor: context.colors.success),
        );
      }
    }
  }

  ImageProvider? _getAvatarProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      final base64Str = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: context.colors.textMain, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: context.colors.surface,
                          backgroundImage: _getAvatarProvider(user.photoUrl),
                          child: _isUploadingImage 
                              ? const CircularProgressIndicator()
                              : (user.photoUrl.isEmpty ? Icon(Icons.person, size: 60, color: context.colors.textSecondary) : null),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        GestureDetector(
                          onTap: () => _pickImage(context, user.name),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ).animate().fadeIn(delay: 200.ms),
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: context.colors.textSecondary, size: 20),
                          onPressed: () => _editName(context, user.name, user.photoUrl),
                        ),
                      ],
                    ),
                    Text(
                      user.email,
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 16),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              SizedBox(height: 48),

              // Account Details
              Text(
                'Account Details',
                style: TextStyle(color: context.colors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 400.ms),
              SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.calendar_today_rounded, color: context.colors.primary),
                      title: Text('Member Since', style: TextStyle(color: context.colors.textMain)),
                      trailing: Text(
                        '${user.joinedDate.year}-${user.joinedDate.month.toString().padLeft(2, '0')}-${user.joinedDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                    Divider(color: context.colors.background, height: 1),
                    ListTile(
                      leading: Icon(Icons.menu_book_rounded, color: context.colors.accent),
                      title: Text('Enrolled Subjects', style: TextStyle(color: context.colors.textMain)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${user.subjects.length}',
                            style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, color: context.colors.textSecondary, size: 14),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubjectSelectionScreen(isEditing: true)),
                        );
                      },
                    ),
                    Divider(color: context.colors.background, height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.info, color: context.colors.primary),
                      title: Text('About StudyZen', style: TextStyle(color: context.colors.textMain)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: context.colors.textSecondary, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    Divider(color: context.colors.background, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.palette, color: context.colors.warning),
                              SizedBox(width: 16),
                              Text('App Theme', style: TextStyle(color: context.colors.textMain, fontSize: 16)),
                            ],
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: AppThemeType.values.map((type) => _buildThemeCard(context, type)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
              
              SizedBox(height: 48),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.colors.surface,
                        title: Text('Sign Out', style: TextStyle(color: context.colors.textMain)),
                        content: Text('Are you sure you want to sign out?', style: TextStyle(color: context.colors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _signOut(context);
                            },
                            child: Text('Sign Out', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, AppThemeType type) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.currentTheme == type;
    
    Color bgColor;
    Color primaryColor;
    String name;
    
    switch (type) {
      case AppThemeType.midnight:
        bgColor = const Color(0xFF0A0A0F);
        primaryColor = const Color(0xFF7C6EFA);
        name = 'Midnight';
        break;
      case AppThemeType.aurora:
        bgColor = const Color(0xFF0A1628);
        primaryColor = const Color(0xFF00D4AA);
        name = 'Aurora';
        break;
      case AppThemeType.sunset:
        bgColor = const Color(0xFF1A0A0F);
        primaryColor = const Color(0xFFFF6B6B);
        name = 'Sunset';
        break;
      case AppThemeType.ocean:
        bgColor = const Color(0xFF050D1A);
        primaryColor = const Color(0xFF0EA5E9);
        name = 'Ocean';
        break;
      case AppThemeType.pureLight:
        bgColor = const Color(0xFFF8F8FF);
        primaryColor = const Color(0xFF7C6EFA);
        name = 'Pure Light';
        break;
    }

    return GestureDetector(
      onTap: () => themeProvider.setTheme(type),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : context.colors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: isSelected 
                  ? Icon(LucideIcons.check, color: type == AppThemeType.pureLight ? Colors.white : bgColor, size: 14)
                  : null,
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: type == AppThemeType.pureLight ? const Color(0xFF12121A) : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
