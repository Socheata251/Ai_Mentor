import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import 'home_card.dart';

/// Explain / Summarize / Solve / Quiz
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _QuickAction(label: 'Explain', icon: Icons.menu_book_outlined),
      _QuickAction(label: 'Summarize', icon: Icons.description_outlined),
      _QuickAction(label: 'Solve', symbol: '√x'),
      _QuickAction(label: 'Quiz', icon: Icons.psychology_outlined),
    ];

    // Tall tiles on phones, squarer tiles when there is more room.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = constraints.maxWidth < 420 ? 0.78 : 1.05;
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: AspectRatio(aspectRatio: ratio, child: items[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, this.icon, this.symbol});

  final String label;
  final IconData? icon;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onTap: () {
        // TODO: open the matching tool
      },
      child: HomeCard(
        padding: const EdgeInsets.all(6),
        radius: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tile,
                borderRadius: BorderRadius.circular(13),
              ),
              child: symbol != null
                  ? Text(
                      symbol!,
                      style: TextStyle(
                        color: colors.tileIcon,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : Icon(icon, color: colors.tileIcon, size: 21),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
