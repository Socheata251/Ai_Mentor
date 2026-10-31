import 'package:flutter/foundation.dart';

import '../models/message.dart';

class ChatPromptHistory extends ChangeNotifier {
  ChatPromptHistory._();

  static final ChatPromptHistory instance = ChatPromptHistory._();

  final List<ChatMessage> _prompts = [];

  List<ChatMessage> get prompts => List.unmodifiable(_prompts);

  void add(ChatMessage prompt) {
    _prompts.add(prompt);
    notifyListeners();
  }

  /// Questions loaded from the database (only when nothing was asked yet).
  void replaceAllIfEmpty(List<ChatMessage> prompts) {
    if (_prompts.isNotEmpty) return;
    _prompts.addAll(prompts);
    notifyListeners();
  }

  void clear() {
    _prompts.clear();
    notifyListeners();
  }
}