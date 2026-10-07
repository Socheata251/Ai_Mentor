import 'package:flutter/foundation.dart';

import '../../../data/models/quiz.dart';

/// Finished quizzes + total XP, shared by the quiz screens.
///
/// In memory only: it resets when the app closes. To keep it, save
/// [records] (e.g. shared_preferences / a database) inside [add].
class QuizHistory extends ChangeNotifier {
  QuizHistory._();
  static final QuizHistory instance = QuizHistory._();

  final List<QuizRecord> _records = []; // newest first
  int _xp = 0;

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

  void add(QuizRecord record) {
    _records.insert(0, record);
    _xp += record.xp;
    notifyListeners();
  }
}
