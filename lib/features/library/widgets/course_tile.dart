import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../data/models/course.dart';
import 'course_style.dart';

/// One curriculum module: icon, SEM badge, code, title, topics, progress.
class CourseTile extends StatelessWidget {
  const CourseTile({super.key, required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final style = CourseStyle.of(course.category);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppPill('SEM ${course.semester}', color: style.color, radius: 6, fontSize: 9),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${course.code} • ${course.credits} CR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.mono,
                          fontFamilyFallback: AppTypography.monoFallback,
                          fontSize: 9.5,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        course.topics,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall!.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${course.percent}%', style: t.labelMedium!.copyWith(fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: course.progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      color: style.color,
                      backgroundColor: c.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
        ],
      ),
    );
  }
}
