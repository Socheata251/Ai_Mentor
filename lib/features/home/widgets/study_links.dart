import 'package:flutter/material.dart';

import '../../../core/router/app_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import 'home_card.dart';

/// "Study" section on Home: two big cards that open the Quiz screen and the
/// Library screen. Menu indexes come from AppNav (2 = Quiz, 4 = Library).
class StudyLinks extends StatelessWidget {
  const StudyLinks({super.key});

  static const int _quizIndex = 2;
  static const int _libraryIndex = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final quiz = _StudyCard(
      icon: Icons.quiz_outlined,
      title: 'Quiz',
      subtitle: 'Test what you know',
      onTap: () => AppNav.goTo(context, _quizIndex),
    );
    final library = _StudyCard(
      icon: Icons.local_library_outlined,
      title: 'Library',
      subtitle: 'Browse all courses',
      onTap: () => AppNav.goTo(context, _libraryIndex),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textStrong,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Side by side when there is room, stacked on small phones.
            if (constraints.maxWidth >= 340) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: quiz),
                  const SizedBox(width: 12),
                  Expanded(child: library),
                ],
              );
            }
            return Column(children: [quiz, const SizedBox(height: 12), library]);
          },
        ),
      ],
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: HomeCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.tile,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.tileIcon, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textStrong,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: colors.textMuted),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: colors.tileIcon),
              ],
            ),
          ],
        ),
      ),
    );
  }
}