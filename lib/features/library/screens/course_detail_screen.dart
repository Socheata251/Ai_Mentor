import 'package:flutter/material.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../data/models/course.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../quiz/widgets/course_quiz_generator.dart';
import '../widgets/course_style.dart';

/// Opens when a course is tapped in the Library.
/// Shows the course info and lets the student generate a quiz for it
/// (the quiz itself runs in the normal Quiz screen) or ask the AI tutor.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _count = 5;

  Course get course => widget.course;

  /// "Trees, Graphs & Sort" -> ["Trees", "Graphs", "Sort"]
  List<String> get _topicChips => course.topics
      .split(RegExp(r'[,&]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _generateQuiz() {
    final quiz = CourseQuizGenerator.generate(course, count: _count);
    Navigator.push(
      context,
      smoothPageRoute<void>(builder: (_) => QuizScreen(initialTopic: quiz)),
    );
  }

  void _askTutor() {
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(topic: course.title, useDemo: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final style = CourseStyle.of(course.category);

    return Scaffold(
      backgroundColor: c.page,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ---- header ----
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onTap: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Course',
                          textAlign: TextAlign.center,
                          style: t.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 42), // keeps the title centered
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---- course info ----
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: style.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(style.icon, color: style.color, size: 28),
                            ),
                            const SizedBox(width: 12),
                            AppPill(course.code, color: style.color, radius: 8, fontSize: 12),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(course.title, style: t.titleLarge),
                        const SizedBox(height: 4),
                        Text(course.topics, style: t.bodyMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _Stat(label: 'Semester', value: '${course.semester}'),
                            const SizedBox(width: 10),
                            _Stat(label: 'Credits', value: '${course.credits}'),
                            const SizedBox(width: 10),
                            _Stat(label: 'Progress', value: '${course.percent}%'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: course.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: c.border,
                            color: c.gradientStart,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---- topics ----
                  Text('What you will cover', style: t.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final topic in _topicChips)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: c.tile,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.tileIcon,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---- generate quiz ----
                  _QuizCard(
                    course: course,
                    count: _count,
                    onCount: (n) => setState(() => _count = n),
                    onGenerate: _generateQuiz,
                  ),
                  const SizedBox(height: 12),

                  // ---- ask tutor ----
                  OutlinedButton.icon(
                    onPressed: _askTutor,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Ask the AI Tutor about this course'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textStrong,
                      side: BorderSide(color: c.border),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.tile.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textStrong,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.course,
    required this.count,
    required this.onCount,
    required this.onGenerate,
  });

  final Course course;
  final int count;
  final ValueChanged<int> onCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final max = CourseQuizGenerator.maxQuestions(course);
    final options = [5, 10].where((n) => n <= max).toList();
    final dedicated = CourseQuizGenerator.hasDedicatedQuestions(course);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: c.tileIcon),
              const SizedBox(width: 8),
              Text('Practice quiz', style: t.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generate a quiz for ${course.title} and test yourself.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text('Number of questions', style: t.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in options)
                ChoiceChip(
                  label: Text('$n'),
                  selected: count == n,
                  onSelected: (_) => onCount(n),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: c.buttonGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: onGenerate,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Quiz',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!dedicated) ...[
            const SizedBox(height: 10),
            Text(
              'There are no questions written for this subject yet, so the '
              'quiz mixes questions from all topics.',
              style: t.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}