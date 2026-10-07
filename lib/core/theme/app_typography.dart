import 'package:flutter/material.dart';

/// Text styles. No font package needed: iOS uses SF Pro automatically.
/// (To use a custom font later, add it to assets and set `fontFamily` here.)
abstract final class AppTypography {
  static const String mono = 'Menlo';
  static const List<String> monoFallback = ['Courier', 'monospace'];

  static const String serif = 'Georgia';
  static const List<String> serifFallback = ['Times New Roman', 'serif'];

  /// Full Material 3 text theme. [strong] = titles/body, [muted] = secondary.
  static TextTheme textTheme(Color strong, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 36, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: strong),
      displayMedium: TextStyle(fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: strong),
      displaySmall: TextStyle(fontSize: 26, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: strong),
      headlineLarge: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: strong),
      headlineMedium: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: strong),
      headlineSmall: TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w700, color: strong),
      titleLarge: TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.w700, color: strong),
      titleMedium: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700, color: strong),
      titleSmall: TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w700, color: strong),
      bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: strong),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.45, color: strong),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
      labelLarge: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700, color: strong),
      labelMedium: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, color: strong),
      labelSmall: TextStyle(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: muted),
    );
  }

  /// Code editor / code blocks.
  static const TextStyle code = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: monoFallback,
    fontSize: 13,
    height: 1.55,
  );

  /// Serif greeting ("Afternoon, Bunthoeun").
  static TextStyle greeting(Color color) => TextStyle(
        fontFamily: serif,
        fontFamilyFallback: serifFallback,
        fontSize: 30,
        height: 1.15,
        color: color,
      );
}
