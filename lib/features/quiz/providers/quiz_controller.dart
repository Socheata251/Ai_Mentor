import 'package:flutter/foundation.dart';

import '../../../data/models/quiz.dart';
import '../widgets/quiz_history.dart';

/// State for ONE quiz run. Plain ChangeNotifier (no extra packages).
class QuizController extends ChangeNotifier {
  QuizController(this.topic)
      : _answers = List<int?>.filled(topic.questions.length, null),
        _hintUsed = List<bool>.filled(topic.questions.length, false);

  // ---- Rules (change freely) ----
  static const secondsPerQuestion = 20;
  static const xpCorrect = 10;
  static const xpHintPenalty = 5; // minus, if the hint was opened
  static const xpSpeedBonus = 3; // plus, if answered quickly
  static const speedBonusSecondsLeft = 10;

  /// Stored in the answers list when the timer runs out.
  static const timedOut = -1;

  final QuizTopic topic;
  final List<int?> _answers;
  final List<bool> _hintUsed;

  int _index = 0;
  int _xp = 0;
  bool _hintShown = false;
  bool _recorded = false;

  List<QuizQuestion> get questions => topic.questions;
  QuizQuestion get current => questions[_index];

  int get index => _index;
  int get number => _index + 1;
  int get total => questions.length;
  bool get isLast => _index >= total - 1;

  /// null = not answered yet, -1 = time ran out, otherwise the option index.
  int? get selected => _answers[_index];
  bool get isAnswered => selected != null;
  bool get didTimeOut => selected == timedOut;
  bool get isCorrect => selected == current.correctIndex;

  bool get hintShown => _hintShown;

  /// XP earned in this run so far.
  int get xp => _xp;

  /// 0..1, counts the current question once it is answered.
  double get progress => total == 0 ? 0 : (_index + (isAnswered ? 1 : 0)) / total;

  void answer(int option, {required int secondsLeft}) {
    if (isAnswered) return;
    _answers[_index] = option;
    if (option == current.correctIndex) {
      var gain = xpCorrect;
      if (_hintUsed[_index]) gain -= xpHintPenalty;
      if (secondsLeft >= speedBonusSecondsLeft) gain += xpSpeedBonus;
      _xp += gain;
    }
    notifyListeners();
  }

  void timeUp() {
    if (isAnswered) return;
    _answers[_index] = timedOut;
    notifyListeners();
  }

  void toggleHint() {
    if (isAnswered) return;
    _hintShown = !_hintShown;
    if (_hintShown) _hintUsed[_index] = true;
    notifyListeners();
  }

  /// Goes to the next question. Returns true when the quiz is finished.
  bool next() {
    if (!isAnswered) return false;
    if (isLast) {
      _finish();
      return true;
    }
    _index++;
    _hintShown = false;
    notifyListeners();
    return false;
  }

  QuizSummary summary() =>
      QuizSummary(topic: topic, answers: List.unmodifiable(_answers), xp: _xp);

  void _finish() {
    if (_recorded) return;
    _recorded = true;
    final s = summary();
    QuizHistory.instance.add(QuizRecord(
      topicId: topic.id,
      topicTitle: topic.title,
      category: topic.category,
      score: s.score,
      total: s.total,
      xp: s.xp,
      date: DateTime.now(),
    ));
  }
}
