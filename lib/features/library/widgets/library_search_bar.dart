import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bottom pill: search field + dark "+" button (add note / upload).
class LibrarySearchBar extends StatelessWidget {
  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(16, 0, 7, 0),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: t.bodyMedium,
              decoration: InputDecoration.collapsed(
                hintText: 'Search library, notes, or code...',
                hintStyle: t.bodyMedium!.copyWith(color: c.textMuted),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: c.textMuted,
                    tooltip: 'Clear',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, size: 22, color: c.onInk),
            ),
          ),
        ],
      ),
    );
  }
}
