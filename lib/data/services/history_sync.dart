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

/// Saves chats and quizzes to the backend (Supabase) and brings them back after sign-in.
///
///   main():          HistorySync.instance.attach();   // once, before runApp
///   after sign-in:   HistorySync.instance.load();
///   on logout:       HistorySync.instance.clearLocal();
class HistorySync {
  HistorySync._();
  static final HistorySync instance = HistorySync._();

  final ApiClient _api = ApiClient.instance;
  final Random _random = Random();

  bool _attached = false;
  bool _muted = false; // true while clearing local data on sign-out
  Timer? _chatTimer;

  /// Quizzes waiting to be sent (offline / server asleep). Retried later.
  final List<_PendingQuiz> _pendingQuizzes = [];
  bool _flushingQuizzes = false;

  /// What the server already has: local chat id -> signature of its messages.
  final Map<String, String> _sentChats = {};
  bool _syncingChats = false;

  bool get _canSync =>
      ApiConfig.useBackend && !_muted && UserSession.instance.isSignedIn;

  // ---------------------------------------------------------------- hooks

  /// Start listening for new quizzes and chat changes. Safe to call more than once.
  void attach() {
    if (_attached) return;
    _attached = true;
    QuizHistory.instance.onAdded = _onQuizAdded;
    ChatConversationHistory.instance.addListener(_onChatsChanged);
  }

  /// Sign-out: forget everything of this student (the server keeps it).
  void clearLocal() {
    _muted = true;
    try {
      _chatTimer?.cancel();
      _pendingQuizzes.clear();
      _sentChats.clear(); // so clearing below is not sent as "deleted"
      QuizHistory.instance.clearAll();
      ChatConversationHistory.instance.clearAll();
    } finally {
      _muted = false;
    }
  }

  // ---------------------------------------------------------------- quizzes

  void _onQuizAdded(QuizRecord record, List<int?>? answers) {
    if (!_canSync || answers == null) return; // the server grades the answers
    _pendingQuizzes.add(_PendingQuiz(
      topicId: record.topicId,
      // The server accepts 0..9 or null; the quiz uses -1 when the time ran out.
      answers: [for (final a in answers) (a == null || a < 0) ? null : a],
      clientRef: '${record.topicId}-${record.date.millisecondsSinceEpoch}-'
          '${_random.nextInt(4294967296).toRadixString(36)}',
    ));
    _flushQuizzes();
  }

  Future<void> _flushQuizzes() async {
    if (_flushingQuizzes || !_canSync) return;
    _flushingQuizzes = true;
    try {
      while (_pendingQuizzes.isNotEmpty && _canSync) {
        final p = _pendingQuizzes.first;
        try {
          await _api.post('/api/quiz/attempts', body: {
            'topicId': p.topicId,
            'answers': p.answers,
            'clientRef': p.clientRef, // same ref = never saved twice
          });
          _pendingQuizzes.removeAt(0);
        } on ApiException catch (e) {
          if (e.isNetwork || e.status >= 500) break; // try again later
          debugPrint('HistorySync: dropped a quiz (${e.status} ${e.message})');
          _pendingQuizzes.removeAt(0); // 4xx: sending again will not help
        }
      }
    } finally {
      _flushingQuizzes = false;
    }
  }

  // ---------------------------------------------------------------- chats

  void _onChatsChanged() {
    if (!_canSync) return;
    _chatTimer?.cancel();
    _chatTimer = Timer(const Duration(seconds: 2), _syncChats);
  }

  String _signature(List<ChatMessage> m) =>
      '${m.length}:${m.last.sentAt.millisecondsSinceEpoch}:${m.last.blocks.length}';

  Future<void> _syncChats() async {
    if (_syncingChats || !_canSync) return;
    _syncingChats = true;
    var retry = false;
    try {
      final current = ChatConversationHistory.instance.conversations;
      final ids = {for (final c in current) c.id};

      // Chats the student deleted.
      for (final id in _sentChats.keys.toList()) {
        if (ids.contains(id)) continue;
        try {
          await _api.delete('/api/chats/${_serverId(id)}');
          _sentChats.remove(id);
        } on ApiException catch (e) {
          if (e.isNetwork || e.status >= 500) {
            retry = true;
          } else {
            _sentChats.remove(id); // already gone / not ours
          }
        }
      }

      // New or changed chats.
      for (final c in current) {
        if (c.messages.isEmpty) continue;
        final sig = _signature(c.messages);
        if (_sentChats[c.id] == sig) continue;
        try {
          await _api.put('/api/history/chats/${_serverId(c.id)}', body: _chatJson(c));
          _sentChats[c.id] = sig;
        } on ApiException catch (e) {
          if (e.isNetwork || e.status >= 500) {
            retry = true;
          } else {
            debugPrint('HistorySync: chat not saved (${e.status} ${e.message})');
            _sentChats[c.id] = sig; // sending the same data again will not help
          }
        }
      }
    } finally {
      _syncingChats = false;
    }
    if (retry) {
      _chatTimer?.cancel();
      _chatTimer = Timer(const Duration(seconds: 30), _syncChats);
    }
  }

  Map<String, dynamic> _chatJson(ChatConversation c) {
    var title = c.title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) title = 'New chat';
    if (title.length > 120) title = title.substring(0, 120);
    // The server keeps at most 60 messages of 30 blocks.
    final msgs = c.messages.length > 60
        ? c.messages.sublist(c.messages.length - 60)
        : c.messages;
    return {
      'title': title,
      'messages': [
        for (final m in msgs)
          if (m.blocks.isNotEmpty)
            {
              'role': m.role == MessageRole.user ? 'user' : 'ai',
              'blocks': [for (final b in m.blocks.take(30)) _blockJson(b)],
              'sentAt': m.sentAt.toUtc().toIso8601String(),
            },
      ],
    };
  }

  // ---------------------------------------------------------------- load

  /// Loads the saved chats and quizzes into the history screens.
  Future<void> load() async {
    if (!_canSync) return;
    unawaited(_flushQuizzes());
    try {
      final data = await _api.get('/api/history') as Map<String, dynamic>;
      _applyQuizzes((data['attempts'] as List? ?? const []).cast<Map<String, dynamic>>());
      _applyChats((data['chats'] as List? ?? const []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      debugPrint('HistorySync: could not load history (${e.status} ${e.message})');
    } catch (e) {
      debugPrint('HistorySync: bad history data: $e');
    }
  }

  void _applyQuizzes(List<Map<String, dynamic>> list) {
    final records = <QuizRecord>[
      for (final a in list)
        QuizRecord(
          topicId: a['topicId'] as String,
          topicTitle: a['topicTitle'] as String? ?? a['topicId'] as String,
          category: _category(a['category'] as String?),
          score: (a['score'] as num).toInt(),
          total: (a['total'] as num).toInt(),
          xp: (a['xp'] as num).toInt(),
          date: DateTime.parse(a['date'] as String).toLocal(),
        ),
    ];
    QuizHistory.instance.replaceAllIfEmpty(records);
  }

  void _applyChats(List<Map<String, dynamic>> list) {
    final have = {for (final c in ChatConversationHistory.instance.conversations) c.id};
    final loaded = <ChatConversation>[];
    for (final c in list) {
      final id = c['id'] as String;
      if (have.contains(id)) continue;
      final messages = <ChatMessage>[
        for (final m in (c['messages'] as List? ?? const []).cast<Map<String, dynamic>>())
          ChatMessage(
            id: ChatMessage.newId(),
            role: m['role'] == 'user' ? MessageRole.user : MessageRole.ai,
            blocks: [
              for (final b in (m['blocks'] as List? ?? const []).cast<Map<String, dynamic>>())
                if (_blockFrom(b) case final block?) block,
            ],
            sentAt: DateTime.parse(m['sentAt'] as String).toLocal(),
          ),
      ];
      if (messages.isEmpty || !messages.any((m) => m.role == MessageRole.user)) continue;
      loaded.add(ChatConversation(id: id, messages: messages));
      _sentChats[id] = _signature(messages); // already on the server: do not send back
    }
    ChatConversationHistory.instance.addLoaded(loaded);
  }

  // ---------------------------------------------------------------- helpers

  static QuizCategory _category(String? name) {
    for (final c in QuizCategory.values) {
      if (c.name == name) return c;
    }
    return QuizCategory.mixed;
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// The server wants a UUID for every chat. A local id that is not one is turned into
  /// a UUID that is always the same for that id, so saving again updates the same chat.
  String _serverId(String localId) {
    if (_uuidPattern.hasMatch(localId)) return localId.toLowerCase();
    const mults = [31, 37, 41, 43];
    const seeds = [7, 11, 13, 17];
    final hex = StringBuffer();
    for (var k = 0; k < 4; k++) {
      var h = seeds[k];
      for (final unit in localId.codeUnits) {
        h = (h * mults[k] + unit) & 0xffffffff;
      }
      hex.write(h.toRadixString(16).padLeft(8, '0'));
    }
    final s = hex.toString(); // 32 hex characters
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-4${s.substring(13, 16)}-'
        '8${s.substring(17, 20)}-${s.substring(20, 32)}';
  }

  Map<String, dynamic> _blockJson(MessageBlock b) => switch (b) {
        TextBlock t => {'type': 'text', 'text': t.text},
        CodeSnippetBlock c => {
            'type': 'code',
            'code': c.code,
            if (c.fileName != null) 'fileName': c.fileName,
            if (c.language != null) 'language': c.language,
          },
        TipBlock t => {'type': 'tip', 'text': t.text},
        QuickCheckBlock q => {
            'type': 'quick_check',
            'question': q.question,
            'options': [
              for (final o in q.options)
                {'label': o.label, if (o.emoji != null) 'emoji': o.emoji},
            ],
            'correctIndex': q.correctIndex,
            if (q.explanation != null) 'explanation': q.explanation,
            'answerBlocks': [for (final a in q.answerBlocks) _blockJson(a)],
          },
      };

  MessageBlock? _blockFrom(Map<String, dynamic> b) {
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
              if (_blockFrom(a) case final block?) block,
          ],
        );
    }
    return null; // unknown block type: skip it
  }
}

class _PendingQuiz {
  _PendingQuiz({required this.topicId, required this.answers, required this.clientRef});
  final String topicId;
  final List<int?> answers;
  final String clientRef;
}