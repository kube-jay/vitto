import 'package:flutter/material.dart';

/// Shared responsive tokens.
abstract final class Breakpoints {
  static const double compact = 600;
  static const double expanded = 900;
  static const double maxContentWidth = 1200;
}

abstract final class AppTheme {
  static const _seed = Color(0xFF0F7B5F);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
