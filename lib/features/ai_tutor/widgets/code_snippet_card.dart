import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/syntax_highlighter.dart';

/// Dark code block: window dots, file name, copy button, syntax colors.
class CodeSnippetCard extends StatefulWidget {
  const CodeSnippetCard({
    super.key,
    required this.code,
    this.fileName,
    this.language,
  });

  final String code;
  final String? fileName;
  final String? language;

  @override
  State<CodeSnippetCard> createState() => _CodeSnippetCardState();
}

class _CodeSnippetCardState extends State<CodeSnippetCard> {
  static const _grey = Color(0xFF94A3B8);

  late List<TextSpan> _spans = _highlight();
  bool _copied = false;

  // FAST: highlighted once, not on every rebuild.
  List<TextSpan> _highlight() => SyntaxHighlighter.highlight(
        widget.code,
        base: AppTypography.code.copyWith(fontSize: 12.5),
      );

  @override
  void didUpdateWidget(CodeSnippetCard old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) _spans = _highlight();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = widget.fileName ?? widget.language ?? 'code';

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.codeBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
              child: Row(
                children: [
                  for (final dot in const [
                    Color(0xFFFF5F57),
                    Color(0xFFFEBC2E),
                    Color(0xFF28C840),
                  ])
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.code.copyWith(fontSize: 11, color: _grey),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: 'Copy code',
                    onPressed: _copy,
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      color: _copied ? c.success : _grey,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text.rich(TextSpan(children: _spans)),
            ),
          ],
        ),
      ),
    );
  }
}
