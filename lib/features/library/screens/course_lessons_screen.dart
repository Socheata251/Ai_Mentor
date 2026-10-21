import 'package:flutter/material.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/course.dart';
import '../../../data/models/lesson.dart';
import '../../../data/services/lesson_service.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../widgets/course_style.dart';
import '../widgets/lesson_state_views.dart';
import 'lesson_screen.dart';

/// The lessons of one course (like the W3Schools menu on the left).
/// Open a lesson to read it. The "Ask AI" button is there if it is unclear.
class CourseLessonsScreen extends StatefulWidget {
  const CourseLessonsScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseLessonsScreen> createState() => _CourseLessonsScreenState();
}

class _CourseLessonsScreenState extends State<CourseLessonsScreen> {
  late Future<CourseLessons> _future = LessonService.instance.forCourse(widget.course.code);

  void _reload() {
    setState(() {
      _future = LessonService.instance.forCourse(widget.course.code);
    });
  }

  Future<void> _openLesson(LessonSummary lesson) async {
    await Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => LessonScreen(lessonId: lesson.id, courseTitle: widget.course.title),
      ),
    );
    if (mounted) _reload(); // show the new "done" checks
  }

  void _askAi() {
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(
          topic: widget.course.title,
          useDemo: false,
          initialPrompt:
              'Give me a short overview of ${widget.course.title} (${widget.course.topics}). '
              'What should I learn first? Explain directly, no quiz.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final course = widget.course;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  LessonHeader(title: course.title, subtitle: '${course.code} · ${course.topics}'),
                  Expanded(
                    child: FutureBuilder<CourseLessons>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return LessonErrorView(
                            message: lessonErrorMessage(snap.error),
                            onRetry: _reload,
                          );
                        }
                        final data = snap.data!;
                        if (data.lessons.isEmpty) return _EmptyView(onAskAi: _askAi);
                        return _LessonList(
                          data: data,
                          accent: CourseStyle.of(course.category).color,
                          onOpen: _openLesson,
                          onAskAi: _askAi,
                        );
                      },
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

class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.data,
    required this.accent,
    required this.onOpen,
    required this.onAskAi,
  });

  final CourseLessons data;
  final Color accent;
  final ValueChanged<LessonSummary> onOpen;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final total = data.lessons.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('${data.completedCount} of $total lessons done', style: t.bodySmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : data.completedCount / total,
            minHeight: 6,
            color: accent,
            backgroundColor: c.border,
          ),
        ),
        const SizedBox(height: 16),
        for (final lesson in data.lessons)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LessonTile(lesson: lesson, accent: accent, onTap: () => onOpen(lesson)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAskAi,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Ask AI about this course'),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.accent, required this.onTap});

  final LessonSummary lesson;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final done = lesson.completed;
    final color = done ? c.success : accent;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: done
                ? Icon(Icons.check_rounded, size: 20, color: color)
                : Text('${lesson.position}', style: t.labelLarge!.copyWith(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: t.titleSmall),
                if (lesson.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lesson.summary, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textMuted),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAskAi});

  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 40, color: c.textMuted),
            const SizedBox(height: 12),
            const Text('Lessons for this course are coming soon.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAskAi,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask AI about this course'),
            ),
          ],
        ),
      ),
    );
  }
}