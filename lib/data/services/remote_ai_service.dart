import '../../core/network/api_client.dart';
import '../../features/settings/providers/settings_controller.dart';
import '../models/message.dart';
import 'ai_service.dart';

/// Talks to YOUR backend (POST /api/ai/chat). The AI key lives on the
/// server, never in this app. While the server's AI_API_KEY is empty it
/// answers with mock replies, so the chat still works.
class RemoteAiService implements AiService {
  const RemoteAiService();

  @override
  Future<ChatMessage> reply({
    required List<ChatMessage> history,
    required String userText,
    required String responseLanguage,
  }) async {
    final messages = <Map<String, String>>[
      for (final m in history.length > 20 ? history.sublist(history.length - 20) : history)
        {'role': m.role == MessageRole.user ? 'user' : 'ai', 'text': _textOf(m)},
    ];
    // The controller already added the new prompt to [history].
    if (messages.isEmpty || messages.last['role'] != 'user') {
      messages.add({'role': 'user', 'text': userText});
    }

    final data = await ApiClient.instance.post('/api/ai/chat', body: {
      'messages': messages,
      'language': responseLanguage == 'Khmer' ? 'Khmer' : 'English',
      'hintsFirst': appSettings.hintsFirst,
    }) as Map<String, dynamic>;

    final blocks = <MessageBlock>[
      for (final b in (data['blocks'] as List).cast<Map<String, dynamic>>())
        if (_block(b) case final block?) block,
    ];
    return ChatMessage.ai(blocks.isEmpty ? const [TextBlock('')] : blocks);
  }

  static String _textOf(ChatMessage m) => m.blocks
      .map((b) => switch (b) {
            TextBlock t => t.text,
            CodeSnippetBlock c => '```${c.language ?? ''}\n${c.code}\n```',
            TipBlock t => 'Tip: ${t.text}',
            QuickCheckBlock q => q.question,
          })
      .join('\n\n');

  static MessageBlock? _block(Map<String, dynamic> b) {
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
        );
    }
    return null; // unknown block type: skip it
  }
}