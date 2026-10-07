import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import 'home_card.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NavLogo(size: 24, color: colors.gradientStart),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  color: colors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "You're spending more time on your weak topics. Keep it up! "
            'Mastery on differentiation will follow.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
