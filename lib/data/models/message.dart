import 'package:flutter/foundation.dart';

enum MessageRole { user, ai }

/// A chat message is a list of blocks, so one AI answer can mix
/// text, code, a tip and a quick-check question.
sealed class MessageBlock {
  const MessageBlock();
}

/// Text. Supports `inline code` and **bold**; lines starting with "• " are bullets.
final class TextBlock extends MessageBlock {
  const TextBlock(this.text);
  final String text;
}

final class CodeSnippetBlock extends MessageBlock {
  const CodeSnippetBlock({required this.code, this.fileName, this.language});
  final String code;
  final String? fileName;
  final String? language;
}

final class TipBlock extends MessageBlock {
  const TipBlock(this.text);
  final String text;
}

final class QuickCheckOption {
  const QuickCheckOption(this.label, {this.emoji});
  final String label;
  final String? emoji;
}

final class QuickCheckBlock extends MessageBlock {
  const QuickCheckBlock({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });
  final String question;
  final List<QuickCheckOption> options;
  final int correctIndex;
  final String? explanation;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.blocks,
    required this.sentAt,
  });

  final String id;
  final MessageRole role;
  final List<MessageBlock> blocks;
  final DateTime sentAt;

  static int _seq = 0;
  static String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static final RegExp _fence = RegExp(r'```(\w*)\n([\s\S]*?)```');

  /// A message typed by the student. Pasted ```fenced``` code becomes a code block.
  factory ChatMessage.userText(String text, {DateTime? at}) {
    final blocks = <MessageBlock>[];
    var last = 0;
    for (final m in _fence.allMatches(text)) {
      final before = text.substring(last, m.start).trim();
      if (before.isNotEmpty) blocks.add(TextBlock(before));
      final lang = m.group(1);
      blocks.add(CodeSnippetBlock(
        code: (m.group(2) ?? '').trimRight(),
        language: (lang == null || lang.isEmpty) ? null : lang,
      ));
      last = m.end;
    }
    final rest = text.substring(last).trim();
    if (rest.isNotEmpty || blocks.isEmpty) blocks.add(TextBlock(rest));
    return ChatMessage(
      id: newId(),
      role: MessageRole.user,
      blocks: blocks,
      sentAt: at ?? DateTime.now(),
    );
  }

  factory ChatMessage.ai(List<MessageBlock> blocks, {DateTime? at}) =>
      ChatMessage(
        id: newId(),
        role: MessageRole.ai,
        blocks: blocks,
        sentAt: at ?? DateTime.now(),
      );

  /// Text + code only (used by the copy button).
  String get plainText => blocks
      .map((b) => switch (b) {
            TextBlock t => t.text,
            CodeSnippetBlock c => c.code,
            TipBlock t => t.text,
            QuickCheckBlock q => q.question,
          })
      .join('\n\n');
}
