import 'package:flutter/foundation.dart';

enum QuizCategory { javascript, python, sql, dataStructures, mixed, dynamicProgramming }

/// One multiple-choice question.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.tag,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.hint,
    required this.explanation,
    this.code,
    this.optionsAreCode = false,
  });

  final String tag; // small label, e.g. "JS ARRAY METHODS"
  final String prompt; // the question text
  final String? code; // optional snippet; write the blank as ______
  final List<String> options;
  final int correctIndex;
  final String hint; // shown when the user taps "Hint"
  final String explanation; // shown after answering
  final bool optionsAreCode; // draw options in a monospace font
}

/// A quiz topic the user can pick on the start screen.
@immutable
class QuizTopic {
  const QuizTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.level,
    required this.fileName,
    required this.langBadge,
    required this.questions,
  });

  final String id; // "js"
  final String title; // "JavaScript Core"
  final String subtitle; // "Arrays, functions, async & more"
  final QuizCategory category;
  final String level; // "Beginner"
  final String fileName; // "snippet.js" (shown on the code block)
  final String langBadge; // "ES6+" (shown on the code block)
  final List<QuizQuestion> questions;

  int get count => questions.length;
}

/// One finished quiz, kept in the history.
@immutable
class QuizRecord {
  const QuizRecord({
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.score,
    required this.total,
    required this.xp,
    required this.date,
  });

  final String topicId;
  final String topicTitle;
  final QuizCategory category;
  final int score;
  final int total;
  final int xp;
  final DateTime date;

  double get percent => total == 0 ? 0 : score / total;
}

/// What the result screen shows after the last question.
@immutable
class QuizSummary {
  const QuizSummary({
    required this.topic,
    required this.answers,
    required this.xp,
  });

  final QuizTopic topic;

  /// One entry per question: chosen option index, -1 = time ran out.
  final List<int?> answers;
  final int xp;

  List<QuizQuestion> get questions => topic.questions;
  int get total => questions.length;

  bool isCorrect(int i) => answers[i] == questions[i].correctIndex;

  int get score {
    var s = 0;
    for (var i = 0; i < total; i++) {
      if (isCorrect(i)) s++;
    }
    return s;
  }

  double get percent => total == 0 ? 0 : score / total;
}