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

  void clear() {
    _prompts.clear();
    notifyListeners();
  }
}
