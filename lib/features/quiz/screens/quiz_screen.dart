import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/syntax_highlighter.dart';
import '../../../data/models/quiz.dart';
import '../providers/quiz_controller.dart';
import '../widgets/quiz_repository.dart';
import '../widgets/topic_picker.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.initialTopicId});

  /// When set, the quiz for this topic starts right away (used by "Retake"
  /// in the history page). Otherwise the topic picker is shown first.
  final String? initialTopicId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizTopic> _topics = const MockQuizRepository().topics();
  QuizController? _quiz;
  QuizSummary? _summary;
  Timer? _timer;
  Timer? _autoAdvance;
  int _secondsLeft = QuizController.secondsPerQuestion;

  @override
  void initState() {
    super.initState();
    final id = widget.initialTopicId;
    if (id == null) return;
    for (final topic in _topics) {
      if (topic.id == id) {
        _quiz = QuizController(topic);
        _startTimer();
        break;
      }
    }
  }

  void _cancelAutoAdvance() {
    _autoAdvance?.cancel();
    _autoAdvance = null;
  }

  @override
  void dispose() {
    _cancelAutoAdvance();
    _timer?.cancel();
    _quiz?.dispose();
    super.dispose();
  }

  void _start(QuizTopic topic) {
    _cancelAutoAdvance();
    _timer?.cancel();
    _quiz?.dispose();
    setState(() {
      _quiz = QuizController(topic);
      _summary = null;
      _secondsLeft = QuizController.secondsPerQuestion;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final quiz = _quiz;
      if (!mounted || quiz == null || quiz.isAnswered) return;
      if (_secondsLeft <= 1) {
        quiz.timeUp();
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _answer(int option) {
    final quiz = _quiz;
    if (quiz == null) return;
    quiz.answer(option, secondsLeft: _secondsLeft);
    _timer?.cancel();
    _cancelAutoAdvance();
    _autoAdvance = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _next();
    });
  }

  /// Automatically goes to the next question. Finishes the quiz after the last question.
  void _next() {
    final quiz = _quiz;
    if (quiz == null || !quiz.isAnswered) return;
    if (quiz.next()) {
      _timer?.cancel();
      setState(() => _summary = quiz.summary());
      return;
    }
    setState(() => _secondsLeft = QuizController.secondsPerQuestion);
    _startTimer();
  }

  void _chooseAnotherTopic() {
    _cancelAutoAdvance();
    _timer?.cancel();
    _quiz?.dispose();
    setState(() {
      _quiz = null;
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quiz = _quiz;
    final summary = _summary;

    return Scaffold(
      backgroundColor: c.page,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.025),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(
                    summary != null
                        ? 'results'
                        : quiz == null
                        ? 'topics'
                        : 'question-${quiz.number}',
                  ),
                  child: summary != null
                      ? _ResultsView(
                          summary: summary,
                          onChooseAnother: _chooseAnotherTopic,
                        )
                      : quiz == null
                      ? TopicPicker(topics: _topics, onSelect: _start)
                      : ListenableBuilder(
                          listenable: quiz,
                          builder: (context, _) => _QuestionView(
                            quiz: quiz,
                            secondsLeft: _secondsLeft,
                            onAnswer: _answer,
                            onClose: _chooseAnotherTopic,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question view
// ---------------------------------------------------------------------------

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.quiz,
    required this.secondsLeft,
    required this.onAnswer,
    required this.onClose,
  });

  final QuizController quiz;
  final int secondsLeft;
  final ValueChanged<int> onAnswer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final question = quiz.current;

    return Column(
      children: [
        _TopBar(quiz: quiz, onClose: onClose),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                _QuestionCard(quiz: quiz, secondsLeft: secondsLeft),
                const SizedBox(height: 16),
                for (var i = 0; i < question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnswerOption(
                      index: i,
                      label: question.options[i],
                      monospace: question.optionsAreCode,
                      answered: quiz.isAnswered,
                      correct: quiz.isAnswered && question.correctIndex == i,
                      incorrect:
                          quiz.isAnswered &&
                          quiz.selected == i &&
                          !quiz.isCorrect,
                      onTap: () => onAnswer(i),
                    ),
                  ),
                if (quiz.isAnswered) ...[
                  const SizedBox(height: 4),
                  _Explanation(
                    title: quiz.didTimeOut
                        ? "Time's up"
                        : quiz.isCorrect
                        ? 'Correct!'
                        : 'Not quite',
                    body: question.explanation,
                    color: quiz.isCorrect ? c.success : c.danger,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (quiz.isAnswered) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              'Moving to the next question…',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: c.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.quiz, required this.onClose});

  final QuizController quiz;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final count =
        '${quiz.number.toString().padLeft(2, '0')} / ${quiz.total.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Choose another topic',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          _Pill(
            background: c.surface,
            border: c.border,
            child: Text(count, style: text.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 6,
                color: c.border,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: quiz.progress.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: c.buttonGradient),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _Pill(
            background: c.warning.withValues(alpha: 0.14),
            border: c.warning.withValues(alpha: 0.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: c.warning),
                const SizedBox(width: 3),
                Text('${quiz.xp} XP', style: text.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.child,
    required this.background,
    required this.border,
  });

  final Widget child;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.quiz, required this.secondsLeft});

  final QuizController quiz;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final question = quiz.current;
    final number = quiz.number.toString().padLeft(2, '0');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: c.gradientStart.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _HintPill(
                      active: quiz.hintShown,
                      enabled: !quiz.isAnswered,
                      onTap: quiz.toggleHint,
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        question.tag,
                        style: text.labelSmall,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Question '),
                      TextSpan(
                        text: number,
                        style: TextStyle(color: c.gradientEnd),
                      ),
                    ],
                  ),
                  style: text.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IT MENTOR AI • ${quiz.topic.title.toUpperCase()}',
                  style: text.labelSmall?.copyWith(color: c.gradientStart),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  '"${question.prompt}"',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (question.code != null) ...[
                  const SizedBox(height: 14),
                  _CodeBlock(
                    code: question.code!,
                    fileName: quiz.topic.fileName,
                    badge: quiz.topic.langBadge,
                  ),
                ],
                if (quiz.hintShown && !quiz.isAnswered) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: c.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(question.hint, style: text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: _TimerBadge(
              secondsLeft: secondsLeft,
              frozen: quiz.isAnswered,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.secondsLeft, required this.frozen});

  final int secondsLeft;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final low = secondsLeft <= 5 && !frozen;
    final ring = low ? c.danger : c.gradientStart;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ring.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: secondsLeft / QuizController.secondsPerQuestion,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: c.border,
              color: ring,
            ),
          ),
          Text(
            '$secondsLeft',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: low ? c.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: _Pill(
          background: c.warning.withValues(alpha: active ? 0.28 : 0.14),
          border: c.warning.withValues(alpha: 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: c.warning),
              const SizedBox(width: 4),
              Text('Hint', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.fileName,
    required this.badge,
  });

  final String code;
  final String fileName;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = AppTypography.code.copyWith(fontSize: 10.5, height: 1.2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: c.codeBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fileName,
                style: small.copyWith(color: SyntaxHighlighter.comment),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SyntaxHighlighter.function.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: small.copyWith(
                    color: SyntaxHighlighter.function,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText.rich(
            TextSpan(
              children: SyntaxHighlighter.highlight(
                code,
                base: AppTypography.code.copyWith(fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.index,
    required this.label,
    required this.monospace,
    required this.answered,
    required this.correct,
    required this.incorrect,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool monospace;
  final bool answered;
  final bool correct;
  final bool incorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final Color accent = correct
        ? c.success
        : incorrect
        ? c.danger
        : c.tileIcon;
    final Color background = correct || incorrect
        ? accent.withValues(alpha: 0.1)
        : c.surface;
    final Color border = correct || incorrect ? accent : c.border;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: answered ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: border,
              width: correct || incorrect ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: correct || incorrect
                      ? accent.withValues(alpha: 0.18)
                      : c.tile,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: text.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style:
                      (monospace
                              ? AppTypography.code.copyWith(fontSize: 14)
                              : text.bodyLarge)
                          ?.copyWith(
                            color: c.textStrong,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ),
              _Indicator(correct: correct, incorrect: incorrect),
            ],
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.correct, required this.incorrect});

  final bool correct;
  final bool incorrect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (correct || incorrect) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: correct ? c.success : c.danger,
          shape: BoxShape.circle,
        ),
        child: Icon(
          correct ? Icons.check_rounded : Icons.close_rounded,
          size: 16,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.border, width: 1.5),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared gradient button
// ---------------------------------------------------------------------------

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: c.buttonGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: c.gradientEnd.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_pressed != pressed) setState(() => _pressed = pressed);
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
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

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.summary, required this.onChooseAnother});

  final QuizSummary summary;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final percent = (summary.percent * 100).round();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: c.gradientStart.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: c.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Quiz complete', style: text.headlineLarge),
                const SizedBox(height: 4),
                Text(summary.topic.title, style: text.bodyMedium),
                const SizedBox(height: 20),
                Text(
                  '${summary.score} / ${summary.total}',
                  style: text.displayMedium?.copyWith(color: c.gradientEnd),
                ),
                const SizedBox(height: 4),
                Text('$percent% correct', style: text.bodyMedium),
                const SizedBox(height: 14),
                _Pill(
                  background: c.warning.withValues(alpha: 0.14),
                  border: c.warning.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: c.warning),
                      const SizedBox(width: 4),
                      Text('${summary.xp} XP earned', style: text.labelMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _GradientButton(
            label: 'Choose another topic',
            onTap: onChooseAnother,
          ),
        ],
      ),
    );
  }
}
