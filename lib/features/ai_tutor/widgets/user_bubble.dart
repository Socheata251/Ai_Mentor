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
    final a = ScreenAccent.of(context, AppScreen.tutor);
    final t = Theme.of(context).textTheme;
    const onBubble = Colors.white;

    return LayoutBuilder(builder: (context, box) {
    final maxBubble = (box.maxWidth * 0.85).clamp(200.0, 640.0);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, bottom: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubble),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: a.color,
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
    });
  }
}