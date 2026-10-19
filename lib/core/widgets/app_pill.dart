import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Nudges [fg] lighter/darker until it has at least 4.5:1 contrast (WCAG AA)
/// against [bg] with a light tint of itself on top.
Color _readable(Color fg, Color bg) {
  final base = Color.alphaBlend(fg.withValues(alpha: 0.12), bg);
  final darkBg = base.computeLuminance() < 0.5;
  var hsl = HSLColor.fromColor(fg);
  double ratio(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  for (var i = 0; i < 20 && ratio(hsl.toColor(), base) < 4.5; i++) {
    final l = (hsl.lightness + (darkBg ? 0.04 : -0.04)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(l);
  }
  return hsl.toColor();
}

/// Small tinted label: "AI Synced", "SEM 3", status tags...
class AppPill extends StatelessWidget {
  const AppPill(
    this.label, {
    super.key,
    this.color,
    this.radius = 20,
    this.fontSize = 10,
    this.mono = true,
    this.dot = false,
  });

  final String label;
  final Color? color; // defaults to the brand blue
  final double radius;
  final double fontSize;
  final bool mono;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.gradientStart;
    // Text color is adjusted so it is always readable on the tinted background.
    final textColor = _readable(tint, c.surface);
    final small = radius < 10;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: mono ? AppTypography.mono : null,
              fontFamilyFallback: mono ? AppTypography.monoFallback : null,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}