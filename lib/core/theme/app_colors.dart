import 'package:flutter/material.dart';

/// Every app-specific color, light and dark, in ONE place.
/// Read it anywhere with:  final c = context.colors;
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // --- existing (used by the onboarding screen) ---
    required this.card,
    required this.textStrong,
    required this.textSoft,
    required this.textMuted,
    required this.dotActive,
    required this.dotInactive,
    required this.gradientStart,
    required this.gradientEnd,
    required this.glowIdle,
    required this.glowActive,
    required this.glowAlpha,
    // --- new ---
    required this.page,
    required this.surface,
    required this.tile,
    required this.tileIcon,
    required this.border,
    required this.ink,
    required this.onInk,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.codeBackground,
    required this.codeText,
    required this.backgroundGradient,
  });

  // Text
  final Color textStrong; // titles
  final Color textSoft; // light part of a title
  final Color textMuted; // subtitles, hints

  // Surfaces
  final Color page; // scaffold background
  final Color card; // large onboarding card
  final Color surface; // normal cards, sheets, nav bar
  final Color tile; // soft blue icon tile / chip background
  final Color tileIcon; // icon color on a tile
  final Color border; // hairlines and dividers
  final Color ink; // solid dark button / selected nav item
  final Color onInk; // content drawn on top of [ink]

  // Brand gradient (blue -> purple)
  final Color gradientStart;
  final Color gradientEnd;
  final Color glowIdle;
  final Color glowActive;
  final double glowAlpha; // glow + beam strength
  final List<Color> backgroundGradient; // 3 colors, top -> bottom

  // Indicators
  final Color dotActive;
  final Color dotInactive;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Code
  final Color codeBackground;
  final Color codeText;

  /// Horizontal button gradient.
  LinearGradient get buttonGradient =>
      LinearGradient(colors: [gradientStart, gradientEnd]);

  /// Diagonal blue-purple gradient (headers, hero cards, drawer header).
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );

  /// Soft page background gradient.
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: backgroundGradient,
      );

  // ------------------------------------------------------------------
  // Light
  // ------------------------------------------------------------------
  static const light = AppColors(
    card: Color(0xFFFAFAFA),
    textStrong: Colors.black,
    textSoft: Color(0xFF9E9E9E),
    textMuted: Color(0xFF616161),
    dotActive: Colors.black,
    dotInactive: Color(0xFFE0E0E0),
    gradientStart: Colors.blue,
    gradientEnd: Colors.purpleAccent,
    glowIdle: Color(0xFF4A89E8),
    glowActive: Color(0xFF2FA8FF),
    glowAlpha: 0.5,
    page: Color(0xFFD3EBFF),
    surface: Colors.white,
    tile: Color(0xFFD6E4FF),
    tileIcon: Color(0xFF3A5EA8),
    border: Color(0xFFE3E9F4),
    ink: Color(0xFF111B33),
    onInk: Colors.white,
    success: Color(0xFF34B56A),
    warning: Color(0xFFF5A524),
    danger: Color(0xFFE5484D),
    info: Color(0xFF3B82F6),
    codeBackground: Color(0xFF0F172A),
    codeText: Color(0xFFE2E8F0),
    backgroundGradient: [
      Color(0xFFE4EEFC),
      Color(0xFFF2F6FB),
      Color(0xFFE9F0F8),
    ],
  );

  // ------------------------------------------------------------------
  // Dark
  // ------------------------------------------------------------------
  static const dark = AppColors(
    card: Color(0xFF141A30),
    textStrong: Color(0xFFF4F6FF),
    textSoft: Color(0xFF8E97B8),
    textMuted: Color(0xFFA3ABC8),
    dotActive: Colors.white,
    dotInactive: Color(0xFF3A4163),
    gradientStart: Color(0xFF4F7CFF),
    gradientEnd: Color(0xFF8B5CF6),
    glowIdle: Color(0xFF5B8CFF),
    glowActive: Color(0xFF4DB8FF),
    glowAlpha: 0.42, // glow looks stronger on dark, so soften it
    page: Color(0xFF0B1020),
    surface: Color(0xFF1A2140),
    tile: Color(0xFF22305C),
    tileIcon: Color(0xFF8FB0FF),
    border: Color(0xFF2A3355),
    ink: Color(0xFFF4F6FF),
    onInk: Color(0xFF0B1020),
    success: Color(0xFF3DD68C),
    warning: Color(0xFFFFB84D),
    danger: Color(0xFFFF6B6F),
    info: Color(0xFF6EA8FF),
    codeBackground: Color(0xFF0A0E1C),
    codeText: Color(0xFFE2E8F0),
    backgroundGradient: [
      Color(0xFF0B1020),
      Color(0xFF0F1630),
      Color(0xFF0B1020),
    ],
  );

  @override
  AppColors copyWith({
    Color? card,
    Color? textStrong,
    Color? textSoft,
    Color? textMuted,
    Color? dotActive,
    Color? dotInactive,
    Color? gradientStart,
    Color? gradientEnd,
    Color? glowIdle,
    Color? glowActive,
    double? glowAlpha,
    Color? page,
    Color? surface,
    Color? tile,
    Color? tileIcon,
    Color? border,
    Color? ink,
    Color? onInk,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? codeBackground,
    Color? codeText,
    List<Color>? backgroundGradient,
  }) {
    return AppColors(
      card: card ?? this.card,
      textStrong: textStrong ?? this.textStrong,
      textSoft: textSoft ?? this.textSoft,
      textMuted: textMuted ?? this.textMuted,
      dotActive: dotActive ?? this.dotActive,
      dotInactive: dotInactive ?? this.dotInactive,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      glowIdle: glowIdle ?? this.glowIdle,
      glowActive: glowActive ?? this.glowActive,
      glowAlpha: glowAlpha ?? this.glowAlpha,
      page: page ?? this.page,
      surface: surface ?? this.surface,
      tile: tile ?? this.tile,
      tileIcon: tileIcon ?? this.tileIcon,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      codeBackground: codeBackground ?? this.codeBackground,
      codeText: codeText ?? this.codeText,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      card: c(card, other.card),
      textStrong: c(textStrong, other.textStrong),
      textSoft: c(textSoft, other.textSoft),
      textMuted: c(textMuted, other.textMuted),
      dotActive: c(dotActive, other.dotActive),
      dotInactive: c(dotInactive, other.dotInactive),
      gradientStart: c(gradientStart, other.gradientStart),
      gradientEnd: c(gradientEnd, other.gradientEnd),
      glowIdle: c(glowIdle, other.glowIdle),
      glowActive: c(glowActive, other.glowActive),
      glowAlpha: glowAlpha + (other.glowAlpha - glowAlpha) * t,
      page: c(page, other.page),
      surface: c(surface, other.surface),
      tile: c(tile, other.tile),
      tileIcon: c(tileIcon, other.tileIcon),
      border: c(border, other.border),
      ink: c(ink, other.ink),
      onInk: c(onInk, other.onInk),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      info: c(info, other.info),
      codeBackground: c(codeBackground, other.codeBackground),
      codeText: c(codeText, other.codeText),
      backgroundGradient: [
        for (var i = 0; i < backgroundGradient.length; i++)
          c(backgroundGradient[i], other.backgroundGradient[i]),
      ],
    );
  }
}

/// Usage anywhere:  final c = context.colors;  then  c.card, c.textStrong ...
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
