import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/message.dart';
import 'code_snippet_card.dart';
import 'rich_message_text.dart';

/// Student message: dark navy bubble (blue in dark mode), right aligned.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message, required this.userName});

  final ChatMessage message;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const onBubble = Colors.white;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, bottom: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: isDark ? c.gradientStart : const Color(0xFF111B33),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$userName (Student)',
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall!.copyWith(
                          fontSize: 10.5,
                          color: onBubble.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      formatTime(message.sentAt),
                      style: t.bodySmall!.copyWith(
                        fontSize: 10.5,
                        color: onBubble.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final b in message.blocks)
                  switch (b) {
                    CodeSnippetBlock code => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CodeSnippetCard(
                          code: code.code,
                          language: code.language,
                        ),
                      ),
                    TextBlock text => RichMessageText(
                        text.text,
                        style: t.bodyMedium,
                        color: onBubble,
                      ),
                    _ => const SizedBox.shrink(),
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
