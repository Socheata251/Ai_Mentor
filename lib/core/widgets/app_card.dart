import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable rounded card: surface color + hairline border, soft shadow in
/// light mode. Pass [onTap] to make it tappable (ripple stays inside).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.lg,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? c.surface : null,
        gradient: gradient,
        borderRadius: shape,
        border: gradient == null ? Border.all(color: c.border) : null,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F1B2A4A),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
