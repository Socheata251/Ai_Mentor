import 'dart:math' as math;

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
    this.answerBlocks = const [],
  });
  final String question;
  final List<QuickCheckOption> options;
  final int correctIndex;
  final String? explanation;

  /// The AI's full, real answer. The chat adds it as a new AI message
  /// AFTER the student chooses an option (hint -> choose -> real answer).
  final List<MessageBlock> answerBlocks;
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

  /// A random UUID v4. The server only accepts this format for chat ids.
  static String newUuid() {
    final r = math.Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }

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