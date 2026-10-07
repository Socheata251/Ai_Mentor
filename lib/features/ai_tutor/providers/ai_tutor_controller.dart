import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/models/message.dart';
import '../../../data/repositories/chat_conversation_history.dart';
import '../../../data/repositories/chat_prompt_history.dart';
import '../../../data/services/ai_service.dart';

/// State for the AI Tutor chat. Plain ChangeNotifier (no extra packages).
/// Move to Riverpod later by wrapping this class in a provider.
class AiTutorController extends ChangeNotifier {
  AiTutorController({
    this.service = const MockAiService(),
    List<ChatMessage> initial = const [],
    String? conversationId,
  }) : _messages = List.of(initial),
       conversationId = conversationId ?? ChatMessage.newId();

  final AiService service;
  final String conversationId;
  final List<ChatMessage> _messages;
  final Map<String, int> _quickAnswers = {};
  bool _typing = false;
  bool _disposed = false;

  static const suggestions = <String>[
    'Compare Promise.allSettled()',
    'Explain retry backoff logic',
    'Show me a hint only',
  ];

  late final UnmodifiableListView<ChatMessage> messages = UnmodifiableListView(
    _messages,
  );

  bool get isTyping => _typing;

  int? quickAnswerFor(String messageId) => _quickAnswers[messageId];

  void answerQuickCheck(String messageId, int index) {
    if (_quickAnswers.containsKey(messageId)) return;
    _quickAnswers[messageId] = index;
    notifyListeners();
  }

  Future<void> send(String raw, {required String responseLanguage}) async {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;

    final prompt = ChatMessage.userText(text);
    _messages.add(prompt);
    ChatPromptHistory.instance.add(prompt);
    ChatConversationHistory.instance.save(conversationId, _messages);
    _typing = true;
    notifyListeners();

    try {
      final reply = await service.reply(
        history: messages,
        userText: text,
        responseLanguage: responseLanguage,
      );
      if (_disposed) return;
      _messages.add(reply);
      ChatConversationHistory.instance.save(conversationId, _messages);
    } catch (_) {
      if (_disposed) return;
      _messages.add(
        ChatMessage.ai(const [
          TextBlock(
            'Sorry, I could not reach the tutor right now. Please check your connection and try again.',
          ),
        ]),
      );
      ChatConversationHistory.instance.save(conversationId, _messages);
    } finally {
      _typing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _quickAnswers.clear();
    ChatConversationHistory.instance.remove(conversationId);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
