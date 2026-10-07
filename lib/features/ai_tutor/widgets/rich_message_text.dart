import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Renders chat text with `inline code`, **bold** and "• " bullets.
class RichMessageText extends StatelessWidget {
  const RichMessageText(this.text, {super.key, this.style, this.color});

  final String text;
  final TextStyle? style;

  /// Optional text color override (e.g. white inside the user bubble).
  final Color? color;

  static final RegExp _inline = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*');

  /// Shared with the tip / quick-check widgets.
  static List<InlineSpan> spans(
    String text, {
    required TextStyle base,
    required AppColors colors,
  }) {
    final out = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) out.add(TextSpan(text: text.substring(last, m.start)));
      final code = m.group(1);
      if (code != null) {
        out.add(TextSpan(
          text: code,
          style: TextStyle(
            fontFamily: AppTypography.mono,
            fontFamilyFallback: AppTypography.monoFallback,
            fontSize: (base.fontSize ?? 14) * 0.9,
            color: colors.tileIcon,
            backgroundColor: colors.tile.withValues(alpha: 0.7),
          ),
        ));
      } else {
        out.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ));
      }
      last = m.end;
    }
    if (last < text.length) out.add(TextSpan(text: text.substring(last)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    var base = style ?? Theme.of(context).textTheme.bodyMedium!;
    if (color != null) base = base.copyWith(color: color);

    final children = <Widget>[];
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }
      final bullet = line.startsWith('• ') || line.startsWith('- ');
      final content = bullet ? line.substring(2) : line;
      final rich = Text.rich(
        TextSpan(children: spans(content, base: base, colors: c)),
        style: base,
      );
      children.add(
        bullet
            ? Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('•', style: base),
                    ),
                    Expanded(child: rich),
                  ],
                ),
              )
            : rich,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
