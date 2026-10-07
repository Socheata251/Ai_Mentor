import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Quick follow-up prompts above the input bar.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(
      context,
    ).textTheme.labelMedium!.copyWith(fontSize: 11.5);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Material(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.border)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onTap(items[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(child: Text(items[i], style: style)),
            ),
          ),
        ),
      ),
    );
  }
}
