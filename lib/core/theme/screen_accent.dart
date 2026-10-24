import 'package:flutter/material.dart';

/// Every main screen gets its OWN color so students can tell where they are
/// at a glance. Change a color here and the whole screen follows.
///
/// Use it anywhere:
///   final a = ScreenAccent.of(context, AppScreen.tutor);
///   a.color        -> buttons, labels, selected chips
///   a.soft         -> soft tinted background (chips, tiles)
///   a.pageGradient -> page background
///   a.page         -> Scaffold background
enum AppScreen {
  home,
  tutor,
  quiz,
  library,
  progress,
  schedule,
  history,
  settings,
  profile,
}

@immutable
class ScreenAccent {
  const ScreenAccent({
    required this.color,
    required this.soft,
    required this.border,
    required this.page,
    required this.gradient,
  });

  /// Strong color for buttons, titles and selected states.
  final Color color;

  /// Light tint for chips, tiles and highlighted cards.
  final Color soft;

  /// Tinted hairline for cards and chips.
  final Color border;

  /// Scaffold background.
  final Color page;

  /// Page background, top -> bottom.
  final List<Color> gradient;

  LinearGradient get pageGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: gradient,
  );

  /// Readable text color on top of [color].
  Color get onColor => Colors.white;

  static ScreenAccent of(BuildContext context, AppScreen screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? _dark : _light)[screen]!;
  }

  // ------------------------------------------------------------------
  // Light: soft pastel pages, strong (AA contrast) accents.
  // ------------------------------------------------------------------
  static const Map<AppScreen, ScreenAccent> _light = {
    // Blue - home
    AppScreen.home: ScreenAccent(
      color: Color(0xFF1565C0),
      soft: Color(0xFFD6E4FF),
      border: Color(0xFFB8CFF5),
      page: Color(0xFFD3EBFF),
      gradient: [Color(0xFFE4EEFC), Color(0xFFF2F6FB), Color(0xFFE9F0F8)],
    ),
    // Indigo - AI tutor
    AppScreen.tutor: ScreenAccent(
      color: Color(0xFF4338CA),
      soft: Color(0xFFE5E7FF),
      border: Color(0xFFC7CBFF),
      page: Color(0xFFE8EAFF),
      gradient: [Color(0xFFE6E8FF), Color(0xFFF3F4FF), Color(0xFFEBEDFF)],
    ),
    // Orange - quiz
    AppScreen.quiz: ScreenAccent(
      color: Color(0xFFC2410C),
      soft: Color(0xFFFFE8D6),
      border: Color(0xFFFBC9A3),
      page: Color(0xFFFFEEDD),
      gradient: [Color(0xFFFFEBD8), Color(0xFFFFF7F0), Color(0xFFFFEFE2)],
    ),
    // Teal - library
    AppScreen.library: ScreenAccent(
      color: Color(0xFF0F766E),
      soft: Color(0xFFD3F3EE),
      border: Color(0xFFA7E3DA),
      page: Color(0xFFDDF5F1),
      gradient: [Color(0xFFDAF4EF), Color(0xFFF1FBF9), Color(0xFFE3F6F2)],
    ),
    // Green - progress
    AppScreen.progress: ScreenAccent(
      color: Color(0xFF15803D),
      soft: Color(0xFFD9F5E3),
      border: Color(0xFFB0E6C4),
      page: Color(0xFFE0F6E8),
      gradient: [Color(0xFFDDF5E6), Color(0xFFF3FBF6), Color(0xFFE5F7EC)],
    ),
    // Rose - schedule
    AppScreen.schedule: ScreenAccent(
      color: Color(0xFFBE185D),
      soft: Color(0xFFFFE0EC),
      border: Color(0xFFF9BBD3),
      page: Color(0xFFFFE6F0),
      gradient: [Color(0xFFFFE3EE), Color(0xFFFFF5F9), Color(0xFFFFE9F2)],
    ),
    // Purple - chat & practice history
    AppScreen.history: ScreenAccent(
      color: Color(0xFF7C3AED),
      soft: Color(0xFFEBE0FF),
      border: Color(0xFFD3BDFB),
      page: Color(0xFFEFE7FF),
      gradient: [Color(0xFFECE2FF), Color(0xFFF8F4FF), Color(0xFFF0E9FF)],
    ),
    // Slate - settings
    AppScreen.settings: ScreenAccent(
      color: Color(0xFF475569),
      soft: Color(0xFFE2E8F0),
      border: Color(0xFFCBD5E1),
      page: Color(0xFFE6EBF2),
      gradient: [Color(0xFFE4E9F1), Color(0xFFF4F6F9), Color(0xFFE9EDF3)],
    ),
    // Sky - profile
    AppScreen.profile: ScreenAccent(
      color: Color(0xFF0369A1),
      soft: Color(0xFFD5EEFB),
      border: Color(0xFFA9DBF3),
      page: Color(0xFFDDF1FB),
      gradient: [Color(0xFFD9EFFB), Color(0xFFF0F9FE), Color(0xFFE1F2FC)],
    ),
  };

  // ------------------------------------------------------------------
  // Dark: deep tinted pages, lighter accents.
  // ------------------------------------------------------------------
  static const Map<AppScreen, ScreenAccent> _dark = {
    AppScreen.home: ScreenAccent(
      color: Color(0xFF6EA8FF),
      soft: Color(0xFF22305C),
      border: Color(0xFF2F427A),
      page: Color(0xFF0B1020),
      gradient: [Color(0xFF0B1020), Color(0xFF0F1630), Color(0xFF0B1020)],
    ),
    AppScreen.tutor: ScreenAccent(
      color: Color(0xFFA5A8FF),
      soft: Color(0xFF26275A),
      border: Color(0xFF3A3C80),
      page: Color(0xFF0D0E26),
      gradient: [Color(0xFF0D0E26), Color(0xFF14153A), Color(0xFF0D0E26)],
    ),
    AppScreen.quiz: ScreenAccent(
      color: Color(0xFFFFA463),
      soft: Color(0xFF42260F),
      border: Color(0xFF5E3718),
      page: Color(0xFF1A0F07),
      gradient: [Color(0xFF1A0F07), Color(0xFF26160B), Color(0xFF1A0F07)],
    ),
    AppScreen.library: ScreenAccent(
      color: Color(0xFF4FD1C0),
      soft: Color(0xFF0F3A36),
      border: Color(0xFF17524C),
      page: Color(0xFF06191A),
      gradient: [Color(0xFF06191A), Color(0xFF0B2527), Color(0xFF06191A)],
    ),
    AppScreen.progress: ScreenAccent(
      color: Color(0xFF3DD68C),
      soft: Color(0xFF123B26),
      border: Color(0xFF1B5636),
      page: Color(0xFF07170E),
      gradient: [Color(0xFF07170E), Color(0xFF0C2315), Color(0xFF07170E)],
    ),
    AppScreen.schedule: ScreenAccent(
      color: Color(0xFFFF8DB8),
      soft: Color(0xFF45142B),
      border: Color(0xFF63203E),
      page: Color(0xFF1A0811),
      gradient: [Color(0xFF1A0811), Color(0xFF260D1A), Color(0xFF1A0811)],
    ),
    AppScreen.history: ScreenAccent(
      color: Color(0xFFB794FF),
      soft: Color(0xFF2E1D58),
      border: Color(0xFF42297C),
      page: Color(0xFF110A24),
      gradient: [Color(0xFF110A24), Color(0xFF1A1036), Color(0xFF110A24)],
    ),
    AppScreen.settings: ScreenAccent(
      color: Color(0xFFA9B6C9),
      soft: Color(0xFF263041),
      border: Color(0xFF364359),
      page: Color(0xFF0E131B),
      gradient: [Color(0xFF0E131B), Color(0xFF151C27), Color(0xFF0E131B)],
    ),
    AppScreen.profile: ScreenAccent(
      color: Color(0xFF5CC3F2),
      soft: Color(0xFF0F3447),
      border: Color(0xFF184A63),
      page: Color(0xFF06161F),
      gradient: [Color(0xFF06161F), Color(0xFF0B2230), Color(0xFF06161F)],
    ),
  };
}