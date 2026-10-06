import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}
