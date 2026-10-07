import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/message.dart';
import 'ai_avatar.dart';
import 'code_snippet_card.dart';
import 'quick_check_card.dart';
import 'rich_message_text.dart';
import 'tip_callout.dart';

/// AI answer: avatar + card made of blocks (text, code, tip, quick check)
/// and the copy / like / dislike / listen row.
class AiMessageCard extends StatelessWidget {
  const AiMessageCard({
    super.key,
    required this.message,
    required this.userName,
    required this.quickAnswer,
    required this.onQuickAnswer,
  });

  final ChatMessage message;
  final String userName;
  final int? quickAnswer;
  final ValueChanged<int> onQuickAnswer;

  Widget _block(MessageBlock b) => switch (b) {
    TextBlock t => RichMessageText(t.text),
    CodeSnippetBlock c => CodeSnippetCard(
      code: c.code,
      fileName: c.fileName,
      language: c.language,
    ),
    TipBlock t => TipCallout(text: t.text),
    QuickCheckBlock q => QuickCheckCard(
      block: q,
      userName: userName,
      timeLabel: formatRelative(message.sentAt),
      selected: quickAnswer,
      onSelect: onQuickAnswer,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 10),
            child: AiAvatar(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: isDark ? c.surface : const Color(0xFFF9FAFF),
                border: Border.all(
                  color: isDark ? c.border : const Color(0xFFE6E9FF),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0x0F6A66C8))
                        .withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IT Mentor AI',
                    style: t.labelMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? c.gradientStart : const Color(0xFF3E4A9F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < message.blocks.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _block(message.blocks[i]),
                  ],
                  const SizedBox(height: 4),
                  _Actions(text: message.plainText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatefulWidget {
  const _Actions({required this.text});
  final String text;

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool? _liked; // true = up, false = down, null = none

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget action(
      IconData icon,
      VoidCallback onTap, {
      Color? color,
      String? tip,
    }) => IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 17,
      tooltip: tip,
      color: color ?? c.textMuted,
      onPressed: onTap,
      icon: Icon(icon),
    );

    return Row(
      children: [
        action(Icons.copy_rounded, () {
          Clipboard.setData(ClipboardData(text: widget.text));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Copied'),
                duration: Duration(seconds: 1),
              ),
            );
        }, tip: 'Copy'),
        action(
          _liked == true
              ? Icons.thumb_up_alt_rounded
              : Icons.thumb_up_alt_outlined,
          () => setState(() => _liked = _liked == true ? null : true),
          color: _liked == true ? c.gradientStart : null,
          tip: 'Helpful',
        ),
        action(
          _liked == false
              ? Icons.thumb_down_alt_rounded
              : Icons.thumb_down_alt_outlined,
          () => setState(() => _liked = _liked == false ? null : false),
          color: _liked == false ? c.danger : null,
          tip: 'Not helpful',
        ),
        action(Icons.volume_up_outlined, () {
          // TODO: text-to-speech
        }, tip: 'Listen'),
      ],
    );
  }
}
