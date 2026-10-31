import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/constants/api_config.dart';
import '../../core/network/api_client.dart';
import '../../features/quiz/widgets/quiz_history.dart';
import '../models/message.dart';
import '../models/quiz.dart';
import '../repositories/chat_conversation_history.dart';
import '../repositories/user_session.dart';

/// Copies chats + finished quizzes to the database and loads them back after
/// sign-in. Call [attach] once at startup (main.dart). Every network failure is
/// swallowed: the app keeps working from memory when offline.
///
/// Backend: GET /api/history, PUT /api/history/chats/:id,
///          DELETE /api/chats/:id, POST /api/quiz/attempts
class HistorySync {
  HistorySync._();
  static final HistorySync instance = HistorySync._();

  final ApiClient _api = ApiClient.instance;
  final _rng = Random.secure();

  bool _attached = false;
  bool _loading = false;
  bool _wasSignedIn = false;

  /// Local chat id -> UUID used by the server (local ids are not UUIDs).
  final Map<String, String> _uuids = {};

  /// Local chat id -> "<messageCount>|<updatedAt>" last sent, to find changes.
  final Map<String, String> _synced = {};
  final Map<String, Timer> _timers = {};

  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool get _signedIn => UserSession.instance.email.isNotEmpty;

  /// Hooks everything up. Safe to call more than once.
  void attach() {
    if (_attached || !ApiConfig.useBackend) return;
    _attached = true;

    QuizHistory.instance.onAdded = _saveQuiz;
    ChatConversationHistory.instance.addListener(_onChatsChanged);
    UserSession.instance.addListener(_onSessionChanged);
    _onSessionChanged(); // already signed in before attach()
  }

  // ---------------------------------------------------------------- session

  void _onSessionChanged() {
    final now = _signedIn;
    if (now && !_wasSignedIn) {
      _wasSignedIn = true;
      unawaited(load());
    } else if (!now && _wasSignedIn) {
      _wasSignedIn = false;
      clear();
    }
  }

  /// Sign-out: the next student must not see this history. Safe to call twice.
  void clear() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _uuids.clear();
    _synced.clear();
    QuizHistory.instance.clearAll();
    _loading = true; // do not send the deletions below to the server
    final h = ChatConversationHistory.instance;
    for (final c in List.of(h.conversations)) {
      h.remove(c.id);
    }
    _loading = false;
  }

  // ------------------------------------------------------------------- load

  Future<void> load() async {
    try {
      final data = await _api.get('/api/history') as Map<String, dynamic>;
      _loading = true;

      final attempts = [
        for (final a in (data['attempts'] as List? ?? const []))
          _recordFrom(a as Map<String, dynamic>),
      ];
      QuizHistory.instance.replaceAllIfEmpty(attempts);

      final history = ChatConversationHistory.instance;
      final have = history.conversations.map((c) => c.id).toSet();
      // oldest first, because save() puts the chat at the top of the list
      for (final c in (data['chats'] as List? ?? const []).reversed) {
        final chat = c as Map<String, dynamic>;
        final id = chat['id'] as String;
        if (have.contains(id)) continue;
        final messages = [
          for (final m in (chat['messages'] as List? ?? const []))
            _messageFrom(m as Map<String, dynamic>),
        ];
        if (messages.isEmpty) continue;
        _uuids[id] = id;
        history.save(id, messages);
      }
      _markAllSynced();
    } catch (e) {
      debugPrint('HistorySync load failed: $e');
    } finally {
      _loading = false;
    }
  }

  // ------------------------------------------------------------------ chats

  String _stamp(ChatConversation c) =>
      '${c.messages.length}|${c.updatedAt.toIso8601String()}';

  void _markAllSynced() {
    _synced
      ..clear()
      ..addEntries(ChatConversationHistory.instance.conversations
          .map((c) => MapEntry(c.id, _stamp(c))));
  }

  void _onChatsChanged() {
    if (_loading || !_signedIn) return;
    final current = {
      for (final c in ChatConversationHistory.instance.conversations) c.id: c,
    };

    for (final c in current.values) {
      if (_synced[c.id] == _stamp(c)) continue;
      _timers[c.id]?.cancel();
      // debounce: the controller saves several times while the AI answers
      _timers[c.id] = Timer(const Duration(seconds: 2), () => _saveChat(c.id));
    }
    for (final id in _synced.keys.toList()) {
      if (!current.containsKey(id)) {
        _synced.remove(id);
        _timers.remove(id)?.cancel();
        unawaited(_deleteChat(id));
      }
    }
  }

  Future<void> _saveChat(String localId) async {
    _timers.remove(localId);
    ChatConversation? chat;
    for (final c in ChatConversationHistory.instance.conversations) {
      if (c.id == localId) chat = c;
    }
    if (chat == null) return;

    final stamp = _stamp(chat);
    final messages = chat.messages.length > 60
        ? chat.messages.sublist(chat.messages.length - 60)
        : chat.messages;
    final title = chat.title.trim();
    try {
      await _api.put('/api/history/chats/${_uuidFor(localId)}', body: {
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'messages': [
          for (final m in messages)
            {
              'role': m.role == MessageRole.user ? 'user' : 'ai',
              'blocks': [for (final b in m.blocks) _blockToJson(b)],
              'sentAt': m.sentAt.toUtc().toIso8601String(),
            },
        ],
      });
      _synced[localId] = stamp;
    } catch (e) {
      debugPrint('HistorySync chat save failed: $e');
    }
  }

  Future<void> _deleteChat(String localId) async {
    final uuid = _uuids.remove(localId);
    if (uuid == null) return;
    try {
      await _api.delete('/api/chats/$uuid');
    } catch (e) {
      debugPrint('HistorySync chat delete failed: $e');
    }
  }

  String _uuidFor(String localId) {
    if (_uuidRe.hasMatch(localId)) return localId;
    return _uuids.putIfAbsent(localId, _newUuid);
  }

  String _newUuid() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  // ------------------------------------------------------------------ quiz

  void _saveQuiz(QuizRecord record, List<int?>? answers) {
    if (!_signedIn || answers == null || answers.isEmpty) return;
    unawaited(() async {
      try {
        await _api.post('/api/quiz/attempts', body: {
          'topicId': record.topicId,
          // -1 = time ran out -> null for the server
          'answers': [for (final a in answers) (a == null || a < 0) ? null : a],
          'clientRef':
              '${record.topicId}-${record.date.toUtc().microsecondsSinceEpoch}',
        });
      } catch (e) {
        debugPrint('HistorySync quiz save failed: $e');
      }
    }());
  }

  QuizRecord _recordFrom(Map<String, dynamic> j) => QuizRecord(
        topicId: j['topicId'] as String,
        topicTitle: j['topicTitle'] as String,
        category: QuizCategory.values.asNameMap()[j['category']] ??
            QuizCategory.mixed,
        score: (j['score'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        xp: (j['xp'] as num).toInt(),
        date: DateTime.parse(j['date'] as String),
      );

  // ---------------------------------------------------------- block <-> JSON

  Map<String, dynamic> _blockToJson(MessageBlock b) => switch (b) {
        TextBlock() => {'type': 'text', 'text': b.text},
        TipBlock() => {'type': 'tip', 'text': b.text},
        CodeSnippetBlock() => {
            'type': 'code',
            'code': b.code,
            if (b.fileName != null) 'fileName': b.fileName,
            if (b.language != null) 'language': b.language,
          },
        QuickCheckBlock() => {
            'type': 'quickCheck',
            'question': b.question,
            'options': [
              for (final o in b.options)
                {'label': o.label, if (o.emoji != null) 'emoji': o.emoji},
            ],
            'correctIndex': b.correctIndex,
            if (b.explanation != null) 'explanation': b.explanation,
            'answerBlocks': [for (final a in b.answerBlocks) _blockToJson(a)],
          },
      };

  MessageBlock _blockFrom(Map<String, dynamic> j) {
    switch (j['type']) {
      case 'tip':
        return TipBlock(j['text'] as String? ?? '');
      case 'code':
        return CodeSnippetBlock(
          code: j['code'] as String? ?? '',
          fileName: j['fileName'] as String?,
          language: j['language'] as String?,
        );
      case 'quickCheck':
        return QuickCheckBlock(
          question: j['question'] as String? ?? '',
          options: [
            for (final o in (j['options'] as List? ?? const []))
              QuickCheckOption(
                (o as Map)['label'] as String? ?? '',
                emoji: o['emoji'] as String?,
              ),
          ],
          correctIndex: (j['correctIndex'] as num?)?.toInt() ?? 0,
          explanation: j['explanation'] as String?,
          answerBlocks: [
            for (final a in (j['answerBlocks'] as List? ?? const []))
              _blockFrom(a as Map<String, dynamic>),
          ],
        );
      default:
        return TextBlock(j['text'] as String? ?? '');
    }
  }

  ChatMessage _messageFrom(Map<String, dynamic> j) => ChatMessage(
        id: ChatMessage.newId(),
        role: j['role'] == 'user' ? MessageRole.user : MessageRole.ai,
        blocks: [
          for (final b in (j['blocks'] as List? ?? const []))
            _blockFrom(b as Map<String, dynamic>),
        ],
        sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
      );
}