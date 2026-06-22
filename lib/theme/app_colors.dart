import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

export '../providers/theme_provider.dart' show ThemeColors;

extension BuildContextThemeColors on BuildContext {
  ThemeColors get colors => watch<ThemeProvider>().colors;
}
