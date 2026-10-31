import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/api_config.dart';
import '../../core/network/api_client.dart';
import '../../features/quiz/widgets/quiz_history.dart';
import '../models/message.dart';
import '../models/quiz.dart';
import '../repositories/chat_conversation_history.dart';

/// Saves quiz + chat history to the backend (Supabase) and loads it back after sign-in.
class HistorySync {
  HistorySync._();
  static final HistorySync instance = HistorySync._();

  final _api = ApiClient.instance;
  final Map<String, Timer> _chatTimers = {};
  final Map<String, int> _synced = {}; // chat id -> signature already saved
  bool _started = false;
  bool _muted = false; // true while loading / clearing: do not save or delete

  /// Call once in main(), before runApp.
  void start() {
    if (_started || !ApiConfig.useBackend) return;
    _started = true;

    // Quiz: save every finished quiz.
    QuizHistory.instance.onAdded = (record, answers) {
      unawaited(_saveQuiz(record, answers));
    };

    // Chat: save a chat 1 second after the last change.
    ChatConversationHistory.instance.addListener(_onChatChanged);
  }

  // ---------- LOAD (after sign-in) ----------
  Future<void> load() async {
    if (!ApiConfig.useBackend) return;
    try {
      final data = await _api.get('/api/history') as Map<String, dynamic>;

      final attempts = (data['attempts'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_recordFrom)
          .toList();

      _muted = true;
      try {
        QuizHistory.instance.replaceAllIfEmpty(attempts);
        final chats = (data['chats'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        for (final c in chats) {
          final msgs = (c['messages'] as List? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(_messageFrom)
              .toList();
          ChatConversationHistory.instance.restore(c['id'] as String, msgs);
        }
        _rememberSaved(); // these chats are already on the server
      } finally {
        _muted = false;
      }
    } catch (e) {
      debugPrint('HistorySync.load failed: $e');
    }
  }

  /// Sign-out: remove the old user's history from memory (not from the server).
  void clear() {
    _muted = true;
    try {
      for (final t in _chatTimers.values) {
        t.cancel();
      }
      _chatTimers.clear();
      _synced.clear();
      QuizHistory.instance.clearAll();
      ChatConversationHistory.instance.clearAll();
    } finally {
      _muted = false;
    }
  }

  // ---------- SAVE QUIZ ----------
  Future<void> _saveQuiz(QuizRecord r, List<int?>? answers) async {
    try {
      await _api.post('/api/quiz/attempts', body: {
        'topicId': r.topicId,
        // one entry per question: option index, null = time ran out
        'answers': [
          for (final a in answers ?? const <int?>[]) (a == null || a < 0) ? null : a,
        ],
        // same key = same attempt, so a retry never saves it twice
        'clientRef': '${r.topicId}-${r.date.microsecondsSinceEpoch}',
      });
    } catch (e) {
      debugPrint('HistorySync quiz save failed: $e');
    }
  }

  // ---------- SAVE / DELETE CHAT ----------
  int _signature(ChatConversation c) =>
      Object.hash(c.messages.length, c.updatedAt.microsecondsSinceEpoch);

  void _rememberSaved() {
    for (final c in ChatConversationHistory.instance.conversations) {
      _synced[c.id] = _signature(c);
    }
  }

  void _onChatChanged() {
    if (_muted) return;
    final current = ChatConversationHistory.instance.conversations;

    // Deleted in the app -> delete on the server too.
    final ids = current.map((c) => c.id).toSet();
    for (final id in _synced.keys.where((id) => !ids.contains(id)).toList()) {
      _synced.remove(id);
      _chatTimers.remove(id)?.cancel();
      unawaited(_deleteChat(id));
    }

    // New or changed -> save.
    for (final c in current) {
      final sig = _signature(c);
      if (_synced[c.id] == sig) continue;
      _chatTimers[c.id]?.cancel();
      _chatTimers[c.id] = Timer(const Duration(seconds: 1), () => _saveChat(c.id));
    }
  }

  Future<void> _saveChat(String id) async {
    ChatConversation? c;
    for (final x in ChatConversationHistory.instance.conversations) {
      if (x.id == id) c = x;
    }
    if (c == null || !_isUuid(c.id)) return; // the server only accepts UUID ids
    try {
      final all = c.messages;
      final msgs = all.length > 60 ? all.sublist(all.length - 60) : all;
      final title = c.title.trim().isEmpty ? 'New chat' : c.title.trim();
      await _api.put('/api/history/chats/${c.id}', body: {
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'messages': [
          for (final m in msgs)
            {
              'role': m.role == MessageRole.user ? 'user' : 'ai',
              'blocks': m.blocks.map(_blockToJson).toList(),
              'sentAt': m.sentAt.toUtc().toIso8601String(),
            },
        ],
      });
      _synced[c.id] = _signature(c);
    } catch (e) {
      debugPrint('HistorySync chat save failed: $e');
    }
  }

  Future<void> _deleteChat(String id) async {
    if (!_isUuid(id)) return;
    try {
      await _api.delete('/api/chats/$id');
    } catch (e) {
      debugPrint('HistorySync chat delete failed: $e');
    }
  }

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static bool _isUuid(String s) => _uuid.hasMatch(s);

  // ---------- JSON <-> models ----------
  static Map<String, dynamic> _blockToJson(MessageBlock b) => switch (b) {
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
            'answerBlocks': q.answerBlocks.map(_blockToJson).toList(),
          },
      };

  static MessageBlock? _blockFrom(Map<String, dynamic> b) {
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
              if (_blockFrom(a) case final x?) x,
          ],
        );
    }
    return null;
  }

  static ChatMessage _messageFrom(Map<String, dynamic> m) {
    final blocks = [
      for (final b in (m['blocks'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (_blockFrom(b) case final x?) x,
    ];
    return ChatMessage(
      id: ChatMessage.newId(),
      role: m['role'] == 'user' ? MessageRole.user : MessageRole.ai,
      blocks: blocks.isEmpty ? const [TextBlock('')] : blocks,
      sentAt: DateTime.tryParse(m['sentAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static QuizRecord _recordFrom(Map<String, dynamic> a) => QuizRecord(
        topicId: a['topicId'] as String,
        topicTitle: a['topicTitle'] as String? ?? '',
        category: QuizCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == (a['category'] as String? ?? '').toLowerCase(),
          orElse: () => QuizCategory.mixed,
        ),
        score: (a['score'] as num).toInt(),
        total: (a['total'] as num).toInt(),
        xp: (a['xp'] as num).toInt(),
        date: DateTime.parse(a['date'] as String).toLocal(),
      );
}