import '../models/message.dart';

/// Chat messages <-> the JSON the backend stores (same block format as /api/ai/chat).

Map<String, dynamic> blockToJson(MessageBlock b) => switch (b) {
      TextBlock t => {'type': 'text', 'text': t.text},
      TipBlock t => {'type': 'tip', 'text': t.text},
      CodeSnippetBlock c => {
          'type': 'code',
          'code': c.code,
          if (c.fileName != null) 'fileName': c.fileName,
          if (c.language != null) 'language': c.language,
        },
      QuickCheckBlock q => {
          'type': 'quick_check',
          'question': q.question,
          'options': [
            for (final o in q.options)
              {'label': o.label, if (o.emoji != null) 'emoji': o.emoji},
          ],
          'correctIndex': q.correctIndex,
          if (q.explanation != null) 'explanation': q.explanation,
          'answerBlocks': [for (final a in q.answerBlocks) blockToJson(a)],
        },
    };

MessageBlock? blockFromJson(Map<String, dynamic> b) {
  switch (b['type']) {
    case 'text':
      return TextBlock(b['text'] as String? ?? '');
    case 'tip':
      return TipBlock(b['text'] as String? ?? '');
    case 'code':
      return CodeSnippetBlock(
        code: b['code'] as String? ?? '',
        fileName: b['fileName'] as String?,
        language: b['language'] as String?,
      );
    case 'quick_check':
      return QuickCheckBlock(
        question: b['question'] as String? ?? '',
        options: [
          for (final o in (b['options'] as List? ?? const []).cast<Map<String, dynamic>>())
            QuickCheckOption(o['label'] as String? ?? '', emoji: o['emoji'] as String?),
        ],
        correctIndex: (b['correctIndex'] as num?)?.toInt() ?? 0,
        explanation: b['explanation'] as String?,
        answerBlocks: [
          for (final a in (b['answerBlocks'] as List? ?? const []).cast<Map<String, dynamic>>())
            if (blockFromJson(a) case final block?) block,
        ],
      );
  }
  return null; // unknown block type: skip it
}

Map<String, dynamic> messageToJson(ChatMessage m) => {
      'role': m.role == MessageRole.user ? 'user' : 'ai',
      'blocks': [for (final b in m.blocks) blockToJson(b)],
      'sentAt': m.sentAt.toUtc().toIso8601String(),
    };

ChatMessage messageFromJson(Map<String, dynamic> j) {
  final blocks = <MessageBlock>[
    for (final b in (j['blocks'] as List? ?? const []).cast<Map<String, dynamic>>())
      if (blockFromJson(b) case final block?) block,
  ];
  return ChatMessage(
    id: ChatMessage.newId(),
    role: j['role'] == 'user' ? MessageRole.user : MessageRole.ai,
    blocks: blocks.isEmpty ? const [TextBlock('')] : blocks,
    sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );
}