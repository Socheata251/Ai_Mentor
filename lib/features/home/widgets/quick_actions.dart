import 'package:flutter/material.dart';

import '../../../core/router/app_nav.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/repositories/user_session.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import 'home_card.dart';

/// Explain / Summarize / Solve / Quiz
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  /// Opens the AI Tutor with the matching tab already selected.
  void _openTutor(BuildContext context, String mode) {
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(
          userName: UserSession.instance.name,
          useDemo: false,
          initialMode: mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(
        label: 'Explain',
        icon: Icons.menu_book_outlined,
        onTap: () => _openTutor(context, 'Explain'),
      ),
      _QuickAction(
        label: 'Summarize',
        icon: Icons.description_outlined,
        onTap: () => _openTutor(context, 'Summarize'),
      ),
      _QuickAction(
        label: 'Solve',
        symbol: '√x',
        onTap: () => _openTutor(context, 'Solve'),
      ),
      _QuickAction(
        label: 'Quiz',
        icon: Icons.psychology_outlined,
        onTap: () => AppNav.goTo(context, 2), // opens the Quiz screen
      ),
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
  const _QuickAction({required this.label, this.icon, this.symbol, this.onTap});

  final String label;
  final IconData? icon;
  final String? symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onTap: onTap,
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