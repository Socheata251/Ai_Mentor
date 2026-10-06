import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/models/message.dart';
import '../../../data/repositories/chat_prompt_history.dart';
import '../../../data/services/ai_service.dart';

/// State for the AI Tutor chat. Plain ChangeNotifier (no extra packages).
/// Move to Riverpod later by wrapping this class in a provider.
class AiTutorController extends ChangeNotifier {
  AiTutorController({
    AiService service = const MockAiService(),
    List<ChatMessage> initial = const [],
  }) : _service = service,
       _messages = List.of(initial);

  final AiService _service;
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
    _typing = true;
    notifyListeners();

    try {
      final reply = await _service.reply(
        history: messages,
        userText: text,
        responseLanguage: responseLanguage,
      );
      if (_disposed) return;
      _messages.add(reply);
    } catch (_) {
      if (_disposed) return;
      _messages.add(
        ChatMessage.ai(const [
          TextBlock(
            'Sorry, I could not reach the tutor right now. Please check your connection and try again.',
          ),
        ]),
      );
    } finally {
      _typing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _quickAnswers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
