import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';

/// "ACLEDA University of Business · Faculty of Engineering · [AI Synced]"
class UniversityCard extends StatelessWidget {
  const UniversityCard({
    super.key,
    this.name = 'ACLEDA University of Business',
    this.faculty = 'Faculty of Engineering • CS Major',
  });

  final String name;
  final String faculty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              name.isEmpty ? '?' : name[0],
              style: t.labelLarge!.copyWith(color: c.onInk, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(faculty, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall!.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const AppPill('AI Synced', mono: false, fontSize: 10.5),
        ],
      ),
    );
  }
}
