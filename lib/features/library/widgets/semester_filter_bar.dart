import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Horizontal chips: All Courses · Semester 3 · Semester 4 ...
class SemesterFilterBar extends StatelessWidget {
  const SemesterFilterBar({
    super.key,
    required this.semesters,
    required this.selected,
    required this.onSelect,
  });

  final List<int> semesters;
  final int? selected; // null = All Courses
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int?)>[
      ('All Courses', null),
      for (final s in semesters) ('Semester $s', s),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = items[i];
          return _FilterChip(
            label: label,
            selected: value == selected,
            onTap: () => onSelect(value),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.ink : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? c.ink : c.border),
        ),
        child: Text(
          label,
          style: t.labelMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? c.onInk : c.textStrong,
          ),
        ),
      ),
    );
  }
}
