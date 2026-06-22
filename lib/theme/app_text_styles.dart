import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

extension BuildContextTextStyles on BuildContext {
  AppTextStyles get textStyles => AppTextStyles(this);
}

class AppTextStyles {
  final BuildContext context;
  AppTextStyles(this.context);

  TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: context.colors.textMain,
        letterSpacing: -1.0,
      );

  TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: context.colors.textMain,
        letterSpacing: -0.5,
      );

  TextStyle get displaySmall => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: context.colors.textMain,
      );

  TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: context.colors.textMain,
      );

  TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: context.colors.textMain,
      );

  TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: context.colors.textSecondary,
      );

  TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: context.colors.textSecondary,
      );

  TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: context.colors.textSecondary,
      ).copyWith(height: 1.5);

  TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: context.colors.textMain,
        height: 1.5,
      );
}
