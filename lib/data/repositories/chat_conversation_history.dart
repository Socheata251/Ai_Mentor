import 'package:flutter/foundation.dart';

import '../models/message.dart';

@immutable
class ChatConversation {
  ChatConversation({required this.id, required List<ChatMessage> messages})
    : messages = List.unmodifiable(messages);

  final String id;
  final List<ChatMessage> messages;

  DateTime get startedAt => messages.first.sentAt;
  DateTime get updatedAt => messages.last.sentAt;
  String get title => messages
      .firstWhere((message) => message.role == MessageRole.user)
      .plainText;
  String get preview => messages.last.plainText;
}

class ChatConversationHistory extends ChangeNotifier {
  ChatConversationHistory._();

  static final ChatConversationHistory instance = ChatConversationHistory._();

  final List<ChatConversation> _conversations = [];

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  void save(String id, List<ChatMessage> messages) {
    if (!messages.any((message) => message.role == MessageRole.user)) return;

    _conversations.removeWhere((conversation) => conversation.id == id);
    _conversations.insert(0, ChatConversation(id: id, messages: messages));
    notifyListeners();
  }

  void remove(String id) {
    _conversations.removeWhere((conversation) => conversation.id == id);
    notifyListeners();
  }
}
