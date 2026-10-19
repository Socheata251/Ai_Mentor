import 'dart:math';

import '../../../data/models/course.dart';
import '../../../data/models/quiz.dart';
import 'quiz_repository.dart';

/// Builds a ready-to-play quiz for one [Course].
///
/// Today the questions come from the built-in bank ([MockQuizRepository]).
/// To use a real AI/backend later, replace the body of [generate] with an API
/// call that returns a [QuizTopic]; the screens do not need to change.
class CourseQuizGenerator {
  const CourseQuizGenerator._();

  /// Which quiz-bank topics fit each course category.
  /// Categories not listed here get a mix of every topic.
  static List<String> _topicIdsFor(CourseCategory category) => switch (category) {
    CourseCategory.dataStructures => const ['ds', 'dp'],
    CourseCategory.database => const ['sql'],
    CourseCategory.web => const ['js'],
    _ => const <String>[],
  };

  /// True when the bank has questions written for this course's subject.
  static bool hasDedicatedQuestions(Course course) =>
      _topicIdsFor(course.category).isNotEmpty;

  static List<QuizTopic> _matching(Course course) {
    final ids = _topicIdsFor(course.category);
    return [
      for (final t in const MockQuizRepository().topics())
        if (ids.contains(t.id)) t,
    ];
  }

  static List<QuizQuestion> _pool(Course course) {
    final matched = _matching(course);
    final source =
        matched.isEmpty ? const MockQuizRepository().topics() : matched;
    return [for (final t in source) ...t.questions];
  }

  /// How many different questions can be used for this course.
  static int maxQuestions(Course course) => _pool(course).length;

  /// A new quiz with [count] shuffled questions for [course].
  static QuizTopic generate(Course course, {int count = 5, Random? random}) {
    final matched = _matching(course);
    final pool = _pool(course)..shuffle(random ?? Random());
    final first = matched.isEmpty ? null : matched.first;

    return QuizTopic(
      id: 'course-${course.code.replaceAll(' ', '').toLowerCase()}',
      title: '${course.title} Quiz',
      subtitle: course.topics,
      category: first?.category ?? QuizCategory.mixed,
      level: first?.level ?? 'Mixed',
      fileName: first?.fileName ?? 'snippet',
      langBadge: first?.langBadge ?? 'MIX',
      questions: pool.take(count).toList(),
    );
  }
}