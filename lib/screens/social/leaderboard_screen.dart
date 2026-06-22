import 'dart:convert' as dart_convert;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

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
          'Global Leaderboard',
          style: TextStyle(color: context.colors.textMain, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getTopUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading leaderboard', style: TextStyle(color: context.colors.error)));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(child: Text('No users found', style: TextStyle(color: context.colors.textSecondary)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = context.read<UserProvider>().user?.uid == user.uid;
              
              return _buildLeaderboardTile(context, user, index, isMe)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 * index))
                  .slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, UserModel user, int index, bool isMe) {
    Color? medalColor;
    if (index == 0) {
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (index == 1) medalColor = const Color(0xFFC0C0C0); // Silver
    else if (index == 2) medalColor = const Color(0xFFCD7F32); // Bronze

    ImageProvider? getAvatarProvider(String photoUrl) {
      if (photoUrl.isEmpty) return null;
      if (photoUrl.startsWith('data:image')) {
        return MemoryImage(dart_convert.base64Decode(photoUrl.split(',').last));
      }
      return NetworkImage(photoUrl);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMe ? context.colors.primary.withOpacity(0.15) : context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? context.colors.primary.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${index + 1}',
              style: TextStyle(
                color: medalColor ?? context.colors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            CircleAvatar(
              radius: 24,
              backgroundColor: context.colors.background,
              backgroundImage: getAvatarProvider(user.photoUrl),
              child: user.photoUrl.isEmpty ? Icon(Icons.person, color: context.colors.textSecondary) : null,
            ),
          ],
        ),
        title: Text(
          isMe ? '${user.name} (You)' : user.name,
          style: TextStyle(
            color: isMe ? context.colors.primary : context.colors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${user.level} • ${user.streak}🔥',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${user.xp} XP',
            style: TextStyle(
              color: context.colors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
