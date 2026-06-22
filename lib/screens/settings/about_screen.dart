import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildMadeWithLoveCard(context),
            const SizedBox(height: 16),
            _buildCreditsCard(context),
            const SizedBox(height: 16),
            _buildTechStackCard(context),
            const SizedBox(height: 32),
            _buildLinksSection(context),
            const SizedBox(height: 48),
            Text(
              '© 2026 StudyZen • Made in 🇵🇰',
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo_transparent.png',
          width: 80,
          height: 80,
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          'StudyZen',
          style: context.textStyles.displayLarge.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Text(
          'Your AI Study Companion',
          style: context.textStyles.bodyLarge.copyWith(color: context.colors.textSecondary),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.border),
          ),
          child: Text('v1.0.0', style: context.textStyles.overline),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildMadeWithLoveCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.primary.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '🇵🇰 ❤️ 🧠 ⚡ 🎓 ✨ 💜 🚀',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'Built with Love in Pakistan',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCreditsCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Team', style: context.textStyles.displayMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('👨‍💻', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coded by', style: context.textStyles.bodySmall),
                  Text('Afaq Raza', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('🎨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Designed by', style: context.textStyles.bodySmall),
                  Text('Mafaz Noor', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTechStackCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Built With', style: context.textStyles.displayMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTechPill(context, 'Flutter', '💙'),
              _buildTechPill(context, 'Firebase', '🔥'),
              _buildTechPill(context, 'Groq AI', '🤖'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTechPill(BuildContext context, String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Text(text, style: context.textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Column(
      children: [
        _buildLinkItem(context, '🌟', 'Star on GitHub', 'https://github.com/Afaqraza12'),
        const SizedBox(height: 12),
        _buildLinkItem(context, '📸', 'Instagram', 'https://instagram.com/gm_afaqraza'),
        const SizedBox(height: 12),
        _buildLinkItem(context, '📧', 'Contact Us', 'mailto:afaqraza510@gmail.com'),
      ],
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLinkItem(BuildContext context, String emoji, String text, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: context.textStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
            ),
            Icon(LucideIcons.arrowUpRight, size: 20, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
