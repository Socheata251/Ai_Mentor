import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// Blue-purple "EXAM READINESS · Generate Mock Quiz" call to action.
class ExamBanner extends StatelessWidget {
  const ExamBanner({
    super.key,
    required this.onStart,
    this.subtitle = 'Test yourself on CS 201 Trees & OOP Concepts',
  });

  final VoidCallback onStart;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return AppCard(
      gradient: AppGradients.brand,
      padding: const EdgeInsets.all(16),
      radius: AppRadius.lg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'EXAM READINESS',
                    style: TextStyle(
                      fontFamily: AppTypography.mono,
                      fontFamilyFallback: AppTypography.monoFallback,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate Mock Quiz',
                  style: t.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: t.bodySmall!.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: c.gradientStart,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: t.labelMedium!.copyWith(fontWeight: FontWeight.w800),
            ),
            child: const Text('Start AI Test'),
          ),
        ],
      ),
    );
  }
}
