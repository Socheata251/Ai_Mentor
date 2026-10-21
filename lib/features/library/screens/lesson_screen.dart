import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/services/lesson_service.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../ai_tutor/widgets/code_snippet_card.dart';
import '../../ai_tutor/widgets/rich_message_text.dart';
import '../../ai_tutor/widgets/tip_callout.dart';
import '../widgets/lesson_state_views.dart';

/// One lesson page: explanation, code examples, output, tips.
/// No AI is used to show it. If the student is still confused, the
/// "Ask AI" button opens the tutor with this lesson already explained as the topic.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId, required this.courseTitle});

  final int lessonId;
  final String courseTitle;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Future<LessonPage> _future = LessonService.instance.lesson(widget.lessonId);
  Future<LessonPage>? _retry;

  bool? _completed; // set after the student taps "Mark as done"
  bool _saving = false;

  void _reload() => setState(() => _retry = LessonService.instance.lesson(widget.lessonId));

  Future<void> _toggleDone(LessonDetail lesson) async {
    if (_saving) return;
    final next = !(_completed ?? lesson.completed);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await LessonService.instance.setCompleted(lesson.id, next);
      if (mounted) setState(() => _completed = next);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goTo(LessonLink link) {
    Navigator.pushReplacement(
      context,
      smoothPageRoute<void>(
        builder: (_) => LessonScreen(lessonId: link.id, courseTitle: widget.courseTitle),
      ),
    );
  }

  void _askAi(LessonDetail lesson) {
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(
          topic: lesson.courseTitle,
          useDemo: false,
          initialPrompt:
              'I am reading the lesson "${lesson.title}" in ${lesson.courseTitle} and I did not understand it. '
              'Please explain it in a simple way with one small example. Explain directly, no quiz.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: FutureBuilder<LessonPage>(
                future: _retry ?? _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Column(
                      children: [
                        LessonHeader(title: widget.courseTitle),
                        const Expanded(child: Center(child: CircularProgressIndicator())),
                      ],
                    );
                  }
                  if (snap.hasError) {
                    return Column(
                      children: [
                        LessonHeader(title: widget.courseTitle),
                        Expanded(
                          child: LessonErrorView(
                            message: lessonErrorMessage(snap.error),
                            onRetry: _reload,
                          ),
                        ),
                      ],
                    );
                  }
                  return _buildLesson(context, snap.data!);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLesson(BuildContext context, LessonPage page) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final lesson = page.lesson;
    final done = _completed ?? lesson.completed;

    return Column(
      children: [
        LessonHeader(
          title: lesson.courseTitle,
          subtitle: 'Lesson ${lesson.position} of ${lesson.total}',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(lesson.title, style: t.headlineMedium),
              if (lesson.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(lesson.summary, style: t.bodyMedium?.copyWith(color: c.textMuted)),
              ],
              const SizedBox(height: 16),
              for (final block in lesson.blocks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBlock(context, block),
                ),
              const SizedBox(height: 12),
              // --- Still confused? Ask AI ---
              Text('Still not clear?', style: t.titleSmall),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _askAi(lesson),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Ask AI to explain this lesson'),
              ),
              const SizedBox(height: 12),
              // --- Mark done ---
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _toggleDone(lesson),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: Icon(done ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                    color: done ? c.success : null),
                label: Text(done ? 'Done (tap to undo)' : 'Mark as done'),
              ),
              const SizedBox(height: 16),
              // --- Previous / Next ---
              Row(
                children: [
                  Expanded(
                    child: page.prev == null
                        ? const SizedBox.shrink()
                        : TextButton.icon(
                            onPressed: () => _goTo(page.prev!),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Previous'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: page.next == null
                        ? const SizedBox.shrink()
                        : FilledButton.tonalIcon(
                            onPressed: () => _goTo(page.next!),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            iconAlignment: IconAlignment.end,
                            label: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlock(BuildContext context, LessonBlock block) {
    final t = Theme.of(context).textTheme;
    return switch (block) {
      LessonHeading b => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(b.text, style: t.titleMedium),
        ),
      LessonText b => RichMessageText(b.text, style: t.bodyMedium?.copyWith(height: 1.6)),
      LessonCode b => CodeSnippetCard(
          code: b.code,
          language: b.language,
          fileName: _fileNameFor(b.language),
        ),
      LessonOutput b => _OutputBox(text: b.text),
      LessonTip b => TipCallout(text: b.text),
    };
  }

  static String? _fileNameFor(String? language) => switch (language) {
        'html' => 'index.html',
        'css' => 'style.css',
        'js' => 'script.js',
        'py' => 'main.py',
        'sql' => 'query.sql',
        'dart' => 'main.dart',
        'java' => 'Main.java',
        _ => null,
      };
}

class _OutputBox extends StatelessWidget {
  const _OutputBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tile.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OUTPUT', style: t.labelSmall),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: AppTypography.code.copyWith(fontSize: 12.5, color: c.textStrong),
          ),
        ],
      ),
    );
  }
}