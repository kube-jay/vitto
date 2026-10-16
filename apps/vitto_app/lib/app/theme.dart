import 'package:flutter/material.dart';

/// Shared responsive tokens.
abstract final class Breakpoints {
  static const double compact = 600;
  static const double expanded = 900;
  static const double maxContentWidth = 1200;
}

/// Brand palette: white surfaces with dark blue as the single accent.
abstract final class VittoColors {
  static const navy = Color(0xFF0B2D6B);
  static const navyPressed = Color(0xFF07204F);
  static const navySoft = Color(0xFFE7EDF8);
  static const ink = Color(0xFF0F1B33);
  static const muted = Color(0xFF5B6B85);
  static const field = Color(0xFFF2F5FA);
  static const line = Color(0xFFDCE3EE);
  static const white = Colors.white;
  static const danger = Color(0xFFC62828);
}

abstract final class AppTheme {
  static const fontFamily = 'Onest';

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: VittoColors.navy,
      onPrimary: VittoColors.white,
      primaryContainer: VittoColors.navySoft,
      onPrimaryContainer: VittoColors.navy,
      secondary: VittoColors.navy,
      onSecondary: VittoColors.white,
      secondaryContainer: VittoColors.navySoft,
      onSecondaryContainer: VittoColors.navy,
      surface: VittoColors.white,
      onSurface: VittoColors.ink,
      onSurfaceVariant: VittoColors.muted,
      surfaceContainerLowest: VittoColors.white,
      surfaceContainerLow: VittoColors.field,
      surfaceContainer: VittoColors.field,
      surfaceContainerHigh: VittoColors.field,
      surfaceContainerHighest: VittoColors.field,
      outline: VittoColors.line,
      outlineVariant: VittoColors.line,
      error: VittoColors.danger,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: VittoColors.white,
    );
    final radius = BorderRadius.circular(12);

    return base.copyWith(
      textTheme: _withWeightAxis(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: VittoColors.white,
        foregroundColor: VittoColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: VittoColors.line, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VittoColors.field,
        hintStyle: const TextStyle(color: VittoColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: VittoColors.navy, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VittoColors.navy,
          foregroundColor: VittoColors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: _weighted(const TextStyle(fontSize: 15), FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VittoColors.navy,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: VittoColors.line),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: VittoColors.navy),
      ),
      cardTheme: CardThemeData(
        color: VittoColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: VittoColors.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VittoColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VittoColors.navySoft,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _weighted(
            TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? VittoColors.navy
                  : VittoColors.muted,
            ),
            FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? VittoColors.navy
                : VittoColors.muted,
          ),
        ),
      ),
    );
  }

  /// Onest ships as a variable font, so each weight must also drive the
  /// `wght` axis for bold text to actually render bold.
  static TextTheme _withWeightAxis(TextTheme t) => t
      .apply(bodyColor: VittoColors.ink, displayColor: VittoColors.ink)
      .copyWith(
        displayLarge: _weighted(t.displayLarge),
        displayMedium: _weighted(t.displayMedium),
        displaySmall: _weighted(t.displaySmall),
        headlineLarge: _weighted(t.headlineLarge, FontWeight.w700),
        headlineMedium: _weighted(t.headlineMedium, FontWeight.w700),
        headlineSmall: _weighted(t.headlineSmall, FontWeight.w700),
        titleLarge: _weighted(t.titleLarge, FontWeight.w700),
        titleMedium: _weighted(t.titleMedium, FontWeight.w600),
        titleSmall: _weighted(t.titleSmall, FontWeight.w600),
        bodyLarge: _weighted(t.bodyLarge),
        bodyMedium: _weighted(t.bodyMedium),
        bodySmall: _weighted(t.bodySmall),
        labelLarge: _weighted(t.labelLarge, FontWeight.w600),
        labelMedium: _weighted(t.labelMedium, FontWeight.w500),
        labelSmall: _weighted(t.labelSmall, FontWeight.w500),
      );

  static TextStyle _weighted(TextStyle? style, [FontWeight? weight]) {
    final s = style ?? const TextStyle();
    final w = weight ?? s.fontWeight ?? FontWeight.w400;
    return s.copyWith(
      fontWeight: w,
      fontVariations: [FontVariation('wght', w.value.toDouble())],
    );
  }
}
