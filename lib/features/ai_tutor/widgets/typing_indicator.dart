import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'ai_avatar.dart';

/// Three bouncing dots while the AI is "thinking".
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const AiAvatar(),
          const SizedBox(width: 10),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.gradientStart.withValues(alpha: _opacity(i)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _opacity(int i) {
    final t = (_c.value + i * 0.2) % 1.0;
    return 0.3 + 0.7 * (1 - (t * 2 - 1).abs());
  }
}
