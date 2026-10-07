import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/message.dart';
import 'rich_message_text.dart';

/// Quick check card: tap an answer, see right/wrong feedback and explanation.
class QuickCheckCard extends StatelessWidget {
  const QuickCheckCard({
    super.key,
    required this.block,
    required this.userName,
    required this.timeLabel,
    required this.selected,
    required this.onSelect,
  });

  final QuickCheckBlock block;
  final String userName;
  final String timeLabel;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final answered = selected != null;
    final correct = selected == block.correctIndex;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tile.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'QUICK CHECK FOR ${userName.toUpperCase()}',
                style: t.labelSmall!.copyWith(
                  color: c.gradientStart,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichMessageText(block.question, style: t.titleSmall),
          const SizedBox(height: 10),
          for (var i = 0; i < block.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Option(
                letter: String.fromCharCode(65 + i),
                option: block.options[i],
                state: !answered
                    ? _OptionState.idle
                    : i == block.correctIndex
                    ? _OptionState.correct
                    : i == selected
                    ? _OptionState.wrong
                    : _OptionState.dimmed,
                onTap: answered
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onSelect(i);
                      },
              ),
            ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                !answered
                    ? 'Tap an option to answer'
                    : correct
                    ? 'Correct! 🎉'
                    : 'Not quite, see the answer above',
                style: t.bodySmall!.copyWith(
                  fontSize: 10.5,
                  color: !answered
                      ? c.textMuted
                      : correct
                      ? c.success
                      : c.danger,
                ),
              ),
              Text(timeLabel, style: t.bodySmall!.copyWith(fontSize: 10.5)),
            ],
          ),
          if (answered && block.explanation != null) ...[
            const SizedBox(height: 10),
            Text(
              block.explanation!,
              style: t.bodySmall!.copyWith(color: c.textStrong, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({
    required this.letter,
    required this.option,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final QuickCheckOption option;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    final (Color border, Color fill) = switch (state) {
      _OptionState.correct => (c.success, c.success.withValues(alpha: 0.1)),
      _OptionState.wrong => (c.danger, c.danger.withValues(alpha: 0.1)),
      _ => (c.border, c.surface),
    };

    Widget? trailing;
    if (state == _OptionState.correct) {
      trailing = Icon(Icons.check_circle_rounded, size: 18, color: c.success);
    } else if (state == _OptionState.wrong) {
      trailing = Icon(Icons.cancel_rounded, size: 18, color: c.danger);
    } else if (option.emoji != null) {
      trailing = Text(option.emoji!, style: const TextStyle(fontSize: 13));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: state == _OptionState.dimmed ? 0.55 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: border,
              width: state == _OptionState.idle ? 1 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$letter) ${option.label}',
                  style: t.bodySmall!.copyWith(
                    fontSize: 12.5,
                    color: c.textStrong,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }
}
