import 'package:flutter/material.dart';
import 'pocket_tokens.dart';

class PocketTheme {
  static const String uiFont = 'PlusJakartaSans';
  static const String monoFont = 'JetBrainsMono';

  /// Variable-font safe UI text style (passes explicit `FontVariation('wght', ...)` so
  /// PlusJakartaSans-Variable.ttf renders crisp bold/semibold/regular weights on Web & Mobile!).
  static TextStyle ui({
    double size = 14,
    double weight = 500,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: uiFont,
      fontSize: size,
      fontWeight: _toFontWeight(weight),
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }

  /// Variable-font safe tabular monospace style (`JetBrainsMono-Variable.ttf`).
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final wVal = _fromFontWeight(weight);
    return TextStyle(
      fontFamily: monoFont,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', wVal)],
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static FontWeight _toFontWeight(double w) {
    if (w >= 800) return FontWeight.w800;
    if (w >= 700) return FontWeight.w700;
    if (w >= 600) return FontWeight.w600;
    if (w >= 500) return FontWeight.w500;
    return FontWeight.w400;
  }

  static double _fromFontWeight(FontWeight w) => switch (w) {
        FontWeight.w900 => 800,
        FontWeight.w800 => 800,
        FontWeight.w700 => 700,
        FontWeight.w600 => 600,
        FontWeight.w500 => 500,
        _ => 400,
      };

  static ThemeData build(PocketColors c) {
    final brightness = c.isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.brandTerracotta,
      onPrimary: c.textOnAccent,
      primaryContainer: c.tintTerracotta,
      onPrimaryContainer: c.brandTerracottaInk,
      secondary: c.brandIce,
      onSecondary: c.textOnAccent,
      secondaryContainer: c.tintIce,
      onSecondaryContainer: c.brandIce,
      tertiary: c.brandSage,
      onTertiary: c.textOnAccent,
      tertiaryContainer: c.tintSage,
      onTertiaryContainer: c.brandSage,
      error: c.statusError,
      onError: c.textOnAccent,
      surface: c.surfaceCanvas,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
      surfaceContainerLowest: c.surfaceCard,
      surfaceContainerLow: c.surfaceCard,
      surfaceContainer: c.surfaceElevated,
      surfaceContainerHigh: c.surfaceSubtle,
      surfaceContainerHighest: c.surfaceSubtle,
    );

    final textTheme = TextTheme(
      headlineMedium: ui(
        size: 24,
        weight: 800,
        letterSpacing: -0.6,
        color: c.textPrimary,
      ),
      titleLarge: ui(
        size: 20,
        weight: 800,
        letterSpacing: -0.45,
        color: c.textPrimary,
      ),
      titleMedium: ui(
        size: 16,
        weight: 700,
        letterSpacing: -0.25,
        color: c.textPrimary,
      ),
      titleSmall: ui(
        size: 14,
        weight: 700,
        letterSpacing: -0.15,
        color: c.textPrimary,
      ),
      bodyLarge: ui(size: 15, weight: 500, color: c.textPrimary),
      bodyMedium: ui(
        size: 13.5,
        weight: 450,
        height: 1.45,
        color: c.textSecondary,
      ),
      bodySmall: ui(
        size: 12,
        weight: 450,
        height: 1.4,
        color: c.textTertiary,
      ),
      labelLarge: ui(size: 14, weight: 700, color: c.textPrimary),
      labelMedium: ui(size: 12, weight: 650, color: c.textSecondary),
      labelSmall: ui(size: 11, weight: 600, color: c.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surfaceCanvas,
      fontFamily: uiFont,
      extensions: [c],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceCanvas,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ui(
          size: 19,
          weight: 800,
          letterSpacing: -0.4,
          color: c.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.brandTerracotta, width: 1.5),
        ),
        hintStyle: ui(size: 13.5, weight: 450, color: c.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, PocketMetrics.touchWetHand),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PocketMetrics.radiusPill),
          ),
          textStyle: ui(size: 14.5, weight: 700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.surfaceCard;
          return c.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.brandSage;
          return c.surfaceSubtle;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
