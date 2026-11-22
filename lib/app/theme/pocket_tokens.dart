import 'package:flutter/material.dart';

/// Exact Pocket Brew v7 Material 3 dual-theme tokens exported from FigCraft (`bloom-tokens.css`).
@immutable
class PocketColors extends ThemeExtension<PocketColors> {
  const PocketColors({
    required this.surfaceCanvas,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.tintTerracotta,
    required this.tintSage,
    required this.tintIce,
    required this.tintHoney,
    required this.tintBerry,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.brandTerracotta,
    required this.brandTerracottaInk,
    required this.brandEspresso,
    required this.brandSage,
    required this.brandIce,
    required this.brandHoney,
    required this.brandBerry,
    required this.borderSubtle,
    required this.borderStrong,
    required this.statusSuccess,
    required this.statusError,
    required this.isDark,
  });

  final Color surfaceCanvas;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color tintTerracotta;
  final Color tintSage;
  final Color tintIce;
  final Color tintHoney;
  final Color tintBerry;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;
  final Color brandTerracotta;
  final Color brandTerracottaInk;
  final Color brandEspresso;
  final Color brandSage;
  final Color brandIce;
  final Color brandHoney;
  final Color brandBerry;
  final Color borderSubtle;
  final Color borderStrong;
  final Color statusSuccess;
  final Color statusError;
  final bool isDark;

  static const softOat = PocketColors(
    surfaceCanvas: Color(0xFFF6F2EC),
    surfaceCard: Color(0xFFFFFDF9),
    surfaceElevated: Color(0xFFEDE6DC),
    surfaceSubtle: Color(0xFFE3DACD),
    tintTerracotta: Color(0xFFF5E2D9),
    tintSage: Color(0xFFE1EDE5),
    tintIce: Color(0xFFDFECF3),
    tintHoney: Color(0xFFF5E9D2),
    tintBerry: Color(0xFFF1DFE3),
    textPrimary: Color(0xFF1F1915),
    textSecondary: Color(0xFF574C43),
    textTertiary: Color(0xFF73665B),
    textOnAccent: Color(0xFFFFFDF9),
    brandTerracotta: Color(0xFFB85835),
    brandTerracottaInk: Color(0xFF964223),
    brandEspresso: Color(0xFF241C16),
    brandSage: Color(0xFF3F6950),
    brandIce: Color(0xFF356480),
    brandHoney: Color(0xFF945F16),
    brandBerry: Color(0xFF944856),
    borderSubtle: Color(0xFFE4DBCF),
    borderStrong: Color(0xFFC7B8A9),
    statusSuccess: Color(0xFF3B6B4F),
    statusError: Color(0xFFB04038),
    isDark: false,
  );

  static const espressoDusk = PocketColors(
    surfaceCanvas: Color(0xFF141210),
    surfaceCard: Color(0xFF1E1A17),
    surfaceElevated: Color(0xFF27221E),
    surfaceSubtle: Color(0xFF332C26),
    tintTerracotta: Color(0xFF38241C),
    tintSage: Color(0xFF1C2A21),
    tintIce: Color(0xFF192831),
    tintHoney: Color(0xFF332917),
    tintBerry: Color(0xFF331F24),
    textPrimary: Color(0xFFF4EFE8),
    textSecondary: Color(0xFFBFB3A6),
    textTertiary: Color(0xFF94877B),
    textOnAccent: Color(0xFF141210),
    brandTerracotta: Color(0xFFE48F6E),
    brandTerracottaInk: Color(0xFFF3AB8F),
    brandEspresso: Color(0xFFEFE6DC),
    brandSage: Color(0xFF86B598),
    brandIce: Color(0xFF80B4D4),
    brandHoney: Color(0xFFE5B263),
    brandBerry: Color(0xFFDF919E),
    borderSubtle: Color(0xFF2F2924),
    borderStrong: Color(0xFF4D433B),
    statusSuccess: Color(0xFF7BB593),
    statusError: Color(0xFFE57E76),
    isDark: true,
  );

  @override
  PocketColors copyWith({
    Color? surfaceCanvas,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? tintTerracotta,
    Color? tintSage,
    Color? tintIce,
    Color? tintHoney,
    Color? tintBerry,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAccent,
    Color? brandTerracotta,
    Color? brandTerracottaInk,
    Color? brandEspresso,
    Color? brandSage,
    Color? brandIce,
    Color? brandHoney,
    Color? brandBerry,
    Color? borderSubtle,
    Color? borderStrong,
    Color? statusSuccess,
    Color? statusError,
    bool? isDark,
  }) {
    return PocketColors(
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      tintTerracotta: tintTerracotta ?? this.tintTerracotta,
      tintSage: tintSage ?? this.tintSage,
      tintIce: tintIce ?? this.tintIce,
      tintHoney: tintHoney ?? this.tintHoney,
      tintBerry: tintBerry ?? this.tintBerry,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      brandTerracotta: brandTerracotta ?? this.brandTerracotta,
      brandTerracottaInk: brandTerracottaInk ?? this.brandTerracottaInk,
      brandEspresso: brandEspresso ?? this.brandEspresso,
      brandSage: brandSage ?? this.brandSage,
      brandIce: brandIce ?? this.brandIce,
      brandHoney: brandHoney ?? this.brandHoney,
      brandBerry: brandBerry ?? this.brandBerry,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  PocketColors lerp(ThemeExtension<PocketColors>? other, double t) {
    if (other is! PocketColors) return this;
    return PocketColors(
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      tintTerracotta: Color.lerp(tintTerracotta, other.tintTerracotta, t)!,
      tintSage: Color.lerp(tintSage, other.tintSage, t)!,
      tintIce: Color.lerp(tintIce, other.tintIce, t)!,
      tintHoney: Color.lerp(tintHoney, other.tintHoney, t)!,
      tintBerry: Color.lerp(tintBerry, other.tintBerry, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      brandTerracotta: Color.lerp(brandTerracotta, other.brandTerracotta, t)!,
      brandTerracottaInk:
          Color.lerp(brandTerracottaInk, other.brandTerracottaInk, t)!,
      brandEspresso: Color.lerp(brandEspresso, other.brandEspresso, t)!,
      brandSage: Color.lerp(brandSage, other.brandSage, t)!,
      brandIce: Color.lerp(brandIce, other.brandIce, t)!,
      brandHoney: Color.lerp(brandHoney, other.brandHoney, t)!,
      brandBerry: Color.lerp(brandBerry, other.brandBerry, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension PocketThemeContext on BuildContext {
  PocketColors get colors =>
      Theme.of(this).extension<PocketColors>() ?? PocketColors.softOat;
}

class PocketMetrics {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  static const double touchMin = 48;
  static const double touchWetHand = 56;
}
