import 'package:flutter/material.dart';

/// Fixed blue-purple gradients that look the same in light and dark mode
/// (logo tiles, badges, achievement cards). Theme-dependent gradients live
/// on [AppColors] (`buttonGradient`, `brandGradient`, `pageGradient`).
abstract final class AppGradients {
  static const Color blue = Color(0xFF4F7CFF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF4DB8FF);

  /// Main brand gradient (diagonal).
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, purple],
  );

  /// Same colors, left -> right (buttons, progress bars).
  static const LinearGradient brandHorizontal = LinearGradient(
    colors: [blue, purple],
  );

  /// Cooler variant for highlights and charts.
  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, blue],
  );

  /// Gold, for streaks / achievements.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC857), Color(0xFFFF9F43)],
  );

  /// Soft round glow (use inside a RepaintBoundary).
  static RadialGradient glow(Color color, double alpha) => RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
      );
}
