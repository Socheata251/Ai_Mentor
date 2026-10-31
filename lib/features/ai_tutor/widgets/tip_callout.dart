import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'rich_message_text.dart';

/// "💡 Pro Tip" box with a colored bar on the left.
class TipCallout extends StatelessWidget {
  const TipCallout({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = ScreenAccent.of(context, AppScreen.tutor);
    final base = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: c.textStrong,
          height: 1.45,
        );

    // ClipRRect + bar (a Border with one colored side cannot have a radius).
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        color: a.soft,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: a.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: '💡 '),
                      ...RichMessageText.spans(text, base: base, colors: c),
                    ]),
                    style: base,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}