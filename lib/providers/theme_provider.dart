import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { midnight, aurora, sunset, ocean, pureLight }

class ThemeColors {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color primary;
  final Color primaryGlow;
  final Color accent;
  final Color success;
  final Color warning;
  final Color info;
  final Color error;
  final Color textMain;
  final Color textSecondary;
  final Color border;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.primary,
    required this.primaryGlow,
    required this.accent,
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
    required this.textMain,
    required this.textSecondary,
    required this.border,
  });

  static const midnight = ThemeColors(
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF12121A),
    surface2: Color(0xFF1C1C28),
    primary: Color(0xFF7C6EFA),
    primaryGlow: Color(0x267C6EFA), // 15% opacity
    accent: Color(0xFFFA6E9A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    error: Color(0xFFEF4444),
    textMain: Color(0xFFF8F8FF),
    textSecondary: Color(0xFF8B8B9E),
    border: Color(0x0FFFFFFF), // 6% white
  );

  static const aurora = ThemeColors(
    background: Color(0xFF0A1628),
    surface: Color(0xFF121E30),
    surface2: Color(0xFF1A283C),
    primary: Color(0xFF00D4AA),
    primaryGlow: Color(0x2600D4AA),
    accent: Color(0xFFFFA400),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    error: Color(0xFFEF4444),
    textMain: Color(0xFFF8F8FF),
    textSecondary: Color(0xFF8B8B9E),
    border: Color(0x0FFFFFFF),
  );

  static const sunset = ThemeColors(
    background: Color(0xFF1A0A0F),
    surface: Color(0xFF221217),
    surface2: Color(0xFF2A1A1F),
    primary: Color(0xFFFF6B6B),
    primaryGlow: Color(0x26FF6B6B),
    accent: Color(0xFFFCA311),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    error: Color(0xFFEF4444),
    textMain: Color(0xFFF8F8FF),
    textSecondary: Color(0xFF8B8B9E),
    border: Color(0x0FFFFFFF),
  );

  static const ocean = ThemeColors(
    background: Color(0xFF050D1A),
    surface: Color(0xFF0A1425),
    surface2: Color(0xFF101C30),
    primary: Color(0xFF0EA5E9),
    primaryGlow: Color(0x260EA5E9),
    accent: Color(0xFF38BDF8),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    error: Color(0xFFEF4444),
    textMain: Color(0xFFF8F8FF),
    textSecondary: Color(0xFF8B8B9E),
    border: Color(0x0FFFFFFF),
  );

  static const pureLight = ThemeColors(
    background: Color(0xFFF8F8FF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0F0F5),
    primary: Color(0xFF7C6EFA),
    primaryGlow: Color(0x267C6EFA),
    accent: Color(0xFFFA6E9A),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF0EA5E9),
    error: Color(0xFFEF4444),
    textMain: Color(0xFF12121A),
    textSecondary: Color(0xFF6B7280),
    border: Color(0x0F000000), // 6% black
  );

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primary.withOpacity(0.6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get cppGradient => LinearGradient(
    colors: [primary, const Color(0xFF9B8BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get dsaGradient => LinearGradient(
    colors: [const Color(0xFF2CB67D), const Color(0xFF1F8055)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get coalGradient => LinearGradient(
    colors: [const Color(0xFFFF8906), const Color(0xFFE57A05)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get osGradient => LinearGradient(
    colors: [accent, const Color(0xFFFF5470)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get webGradient => LinearGradient(
    colors: [info, const Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.midnight;

  AppThemeType get currentTheme => _currentTheme;

  ThemeColors get colors {
    switch (_currentTheme) {
      case AppThemeType.midnight: return ThemeColors.midnight;
      case AppThemeType.aurora: return ThemeColors.aurora;
      case AppThemeType.sunset: return ThemeColors.sunset;
      case AppThemeType.ocean: return ThemeColors.ocean;
      case AppThemeType.pureLight: return ThemeColors.pureLight;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('app_theme') ?? 'midnight';
    
    _currentTheme = AppThemeType.values.firstWhere(
      (e) => e.toString().split('.').last == themeString,
      orElse: () => AppThemeType.midnight,
    );
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType type) async {
    _currentTheme = type;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', type.toString().split('.').last);
  }
}
