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

  void add(QuizRecord record) {
    _records.insert(0, record);
    _xp += record.xp;
    notifyListeners();
  }
}
