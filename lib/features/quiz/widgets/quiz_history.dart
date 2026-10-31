import 'package:flutter/foundation.dart';

import '../../../data/models/quiz.dart';

/// Finished quizzes + total XP, shared by the quiz screens.
///
/// Kept in memory for the screens. HistorySync copies every finished quiz to the
/// database ([onAdded]) and loads them back after sign-in ([replaceAllIfEmpty]).
class QuizHistory extends ChangeNotifier {
  QuizHistory._();
  static final QuizHistory instance = QuizHistory._();

  final List<QuizRecord> _records = []; // newest first
  int _xp = 0;

  /// Set by HistorySync: called after a quiz is added, with the chosen answers.
  void Function(QuizRecord record, List<int?>? answers)? onAdded;

  List<QuizRecord> get records => List.unmodifiable(_records);
  int get totalXp => _xp;
  int get quizzesTaken => _records.length;

  /// Best score in percent (0 when nothing was taken yet).
  int get bestPercent {
    var best = 0.0;
    for (final r in _records) {
      if (r.percent > best) best = r.percent;
    }
    return (best * 100).round();
  }

  /// Finished runs of one topic, newest first.
  List<QuizRecord> recordsFor(String topicId) =>
      _records.where((r) => r.topicId == topicId).toList();

  /// Best percent (0..100) for one topic, or null if never taken.
  int? bestPercentFor(String topicId) {
    final list = recordsFor(topicId);
    if (list.isEmpty) return null;
    var best = 0.0;
    for (final r in list) {
      if (r.percent > best) best = r.percent;
    }
    return (best * 100).round();
  }

  /// Average accuracy (0..100) for one topic, or null if never taken.
  int? averagePercentFor(String topicId) {
    final list = recordsFor(topicId);
    if (list.isEmpty) return null;
    final sum = list.fold<double>(0, (a, r) => a + r.percent);
    return (sum / list.length * 100).round();
  }

  /// Average accuracy over every quiz (null when nothing was taken yet).
  int? get averagePercent {
    if (_records.isEmpty) return null;
    final sum = _records.fold<double>(0, (a, r) => a + r.percent);
    return (sum / _records.length * 100).round();
  }

  /// Consecutive days with at least one quiz, counting back from today
  /// (or from yesterday, so the streak is not lost before today's quiz).
  int get streakDays {
    final days = <DateTime>{
      for (final r in _records)
        DateTime(r.date.toLocal().year, r.date.toLocal().month, r.date.toLocal().day),
    };
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Adds a finished quiz. A failing sync (offline, server asleep) never breaks the quiz.
  void add(QuizRecord record, {List<int?>? answers}) {
    _records.insert(0, record);
    _xp += record.xp;
    notifyListeners();
    try {
      onAdded?.call(record, answers);
    } catch (e) {
      debugPrint('QuizHistory sync failed: $e');
    }
  }

  /// Quizzes loaded from the database, newest first.
  /// Merges with quizzes already taken in this session (no duplicates), so history
  /// is not lost when the user finishes a quiz before the load completes.
  void replaceAllIfEmpty(List<QuizRecord> loaded) {
    if (loaded.isEmpty) return;
    final existing = List<QuizRecord>.of(_records);
    bool same(QuizRecord a, QuizRecord b) =>
        a.topicId == b.topicId && a.date.isAtSameMomentAs(b.date);
    _records
      ..clear()
      ..addAll(existing)
      ..addAll(loaded.where((l) => !existing.any((e) => same(e, l))))
      ..sort((a, b) => b.date.compareTo(a.date));
    _xp = _records.fold<int>(0, (sum, r) => sum + r.xp);
    notifyListeners();
  }

  /// Sign-out: the next student must not see this history.
  void clearAll() {
    _records.clear();
    _xp = 0;
    notifyListeners();
  }
}