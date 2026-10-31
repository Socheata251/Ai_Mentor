import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../data/models/quiz.dart';
import '../../../data/repositories/user_session.dart';
import '../../quiz/widgets/quiz_history.dart';
import '../../quiz/widgets/quiz_repository.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.userName});

  final String? userName;

  /// The name to show: the one passed in, else the signed-in student.
  String get displayName => userName ?? UserSession.instance.name;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _term = 'This Term';

  void _openTutor(String topic) {
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) => AiTutorScreen(
          userName: widget.displayName,
          useDemo: false,
          topic: topic,
          initialPrompt: 'Help me review $topic. Start with a hint.',
        ),
      ),
    );
  }

  /// Opens the quiz of [topicId] when the quiz bank has it, else the topic picker.
  void _openQuiz([String? topicId]) {
    final known = topicId != null &&
        const MockQuizRepository().topics().any((t) => t.id == topicId);
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) =>
            known ? QuizScreen(initialTopicId: topicId) : const QuizScreen(),
      ),
    );
  }

  /// Page column: phone = full width, tablet = 720, desktop = 2 columns.
  static double _columnWidth(double available) =>
      available >= 900 ? 1040 : (available >= 600 ? 720 : 600);

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever a quiz is finished or the history is loaded after sign-in.
    return ListenableBuilder(
      listenable: QuizHistory.instance,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final history = QuizHistory.instance;
    final stats = _ProgressStats.from(history.records, _term);
    final weakest = stats.weakest;

    return AppShell(
      selectedIndex: 5,
      userName: widget.displayName,
      child: Container(
      decoration: BoxDecoration(gradient: ScreenAccent.of(context, AppScreen.progress).pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          // Same column as the content below, so the title and the
          // "This Term" menu line up with the cards on wide screens.
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _columnWidth(context.contentWidth),
              ),
              child: AppBar(
          automaticallyImplyLeading: false,
          leading: AppMenuButton.hasSidebarOf(context)
              ? null
              : const Center(child: AppMenuButton()),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Progress', style: theme.textTheme.titleMedium),
              Text(
                'IT Mentor AI · Semester 3 & 4',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Select term',
              initialValue: _term,
              onSelected: (term) => setState(() => _term = term),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'This Term', child: Text('This Term')),
                PopupMenuItem(value: 'Last Term', child: Text('Last Term')),
                PopupMenuItem(value: 'All Time', child: Text('All Time')),
              ],
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_term, style: theme.textTheme.labelSmall),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth;
            final contentWidth = available < _columnWidth(available)
                ? available
                : _columnWidth(available);
            // Wide window: two columns side by side instead of one long
            // narrow column with empty space around it.
            final twoColumns = available >= 900;
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: twoColumns
                      ? [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _SummaryCard(stats: stats),
                                    const SizedBox(height: 16),
                                    _TopicsCard(topics: stats.topics, quizzes: stats.quizzes),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _RecommendationCard(
                                      weakest: weakest,
                                      onStart: () => weakest == null
                                          ? _openQuiz()
                                          : _openTutor(weakest.name),
                                    ),
                                    const SizedBox(height: 16),
                                    _StreakCard(history: history),
                                    const SizedBox(height: 16),
                                    _PracticeCard(
                                      weakest: weakest,
                                      onStartQuiz: () => _openQuiz(weakest?.topicId),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ]
                      : [
                          _SummaryCard(stats: stats),
                          const SizedBox(height: 12),
                          _TopicsCard(topics: stats.topics, quizzes: stats.quizzes),
                          const SizedBox(height: 12),
                          _RecommendationCard(
                            weakest: weakest,
                            onStart: () => weakest == null
                                ? _openQuiz()
                                : _openTutor(weakest.name),
                          ),
                          const SizedBox(height: 12),
                          _StreakCard(history: history),
                          const SizedBox(height: 12),
                          _PracticeCard(
                            weakest: weakest,
                            onStartQuiz: () => _openQuiz(weakest?.topicId),
                          ),
                        ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            height: 42,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _columnWidth(context.contentWidth) - 32,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openQuiz(weakest?.topicId),
                    icon: const Icon(Icons.quiz_outlined, size: 17),
                    label: Text(
                      weakest == null
                          ? 'Take a quiz'
                          : 'Generate Quiz on ${weakest.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      backgroundColor: colors.ink,
                      foregroundColor: colors.onInk,
                    ),
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

/// Numbers for one term, computed from the quizzes the student really took.
class _ProgressStats {
  _ProgressStats._({
    required this.answered,
    required this.correct,
    required this.quizzes,
    required this.topics,
    required this.weeklyGain,
  });

  final int answered;
  final int correct;
  final int quizzes;
  final List<_TopicProgress> topics; // newest quiz first
  final int? weeklyGain; // percentage points better than before this week

  double? get accuracy => answered == 0 ? null : correct / answered;

  /// The topic with the lowest average score (null when nothing was taken).
  _TopicProgress? get weakest => topics.isEmpty
      ? null
      : topics.reduce((a, b) => a.value <= b.value ? a : b);

  static double? _accuracy(List<QuizRecord> list) {
    final total = list.fold<int>(0, (sum, r) => sum + r.total);
    if (total == 0) return null;
    return list.fold<int>(0, (sum, r) => sum + r.score) / total;
  }

  factory _ProgressStats.from(List<QuizRecord> records, String term) {
    final now = DateTime.now();
    bool inTerm(QuizRecord r) {
      final age = now.difference(r.date).inDays;
      return switch (term) {
        'Last Term' => age >= 120 && age < 240,
        'All Time' => true,
        _ => age < 120, // This Term = the last 4 months
      };
    }

    final list = records.where(inTerm).toList();

    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final thisWeek = list.where((r) => !r.date.toLocal().isBefore(weekStart)).toList();
    final before = list.where((r) => r.date.toLocal().isBefore(weekStart)).toList();
    int? gain;
    final a = _accuracy(thisWeek);
    final b = _accuracy(before);
    if (a != null && b != null) gain = ((a - b) * 100).round();

    final byTopic = <String, List<QuizRecord>>{};
    for (final r in list) {
      byTopic.putIfAbsent(r.topicId, () => []).add(r);
    }
    final topics = <_TopicProgress>[
      for (final e in byTopic.entries.take(6))
        () {
          final avg = e.value.fold<double>(0, (sum, r) => sum + r.percent) /
              e.value.length;
          return _TopicProgress(e.key, e.value.first.topicTitle, avg,
              warning: avg < 0.6);
        }(),
    ];

    return _ProgressStats._(
      answered: list.fold<int>(0, (sum, r) => sum + r.total),
      correct: list.fold<int>(0, (sum, r) => sum + r.score),
      quizzes: list.length,
      topics: topics,
      weeklyGain: gain,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final _ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accuracy = stats.accuracy;
    final gain = stats.weeklyGain;
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your progress', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Questions answered',
                  value: '${stats.answered}',
                  icon: Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Accuracy',
                  value: accuracy == null ? '—' : '${(accuracy * 100).round()}%',
                  detail: (gain != null && gain > 0) ? '+$gain% this week' : null,
                  icon: Icons.track_changes_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'TOPICS COVERED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textMuted,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.tile.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
              Icon(icon, size: 13, color: colors.tileIcon),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              if (detail != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.success,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard({required this.topics, required this.quizzes});

  final List<_TopicProgress> topics;
  final int quizzes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topics covered', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          if (topics.isEmpty)
            Text(
              'No quiz results yet. Finish a quiz and your topics will appear here.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: colors.textMuted,
              ),
            ),
          for (var index = 0; index < topics.length; index++) ...[
            _TopicRow(topic: topics[index]),
            if (index != topics.length - 1) const SizedBox(height: 11),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: colors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.info),
              const SizedBox(width: 7),
              Text(
                'Recommended next',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.info,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$quizzes ${quizzes == 1 ? 'quiz' : 'quizzes'}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicProgress {
  const _TopicProgress(this.topicId, this.name, this.value,
      {this.warning = false});

  final String topicId;
  final String name;
  final double value;
  final bool warning;
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});

  final _TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = topic.warning ? colors.warning : colors.gradientStart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                topic.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontSize: 10),
              ),
            ),
            Text(
              '${(topic.value * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: topic.warning ? colors.warning : colors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: topic.value,
            minHeight: 4,
            color: color,
            backgroundColor: colors.border.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.weakest, required this.onStart});

  final _TopicProgress? weakest;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ProgressCard(
      color: colors.tile.withValues(alpha: 0.58),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: colors.info, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weakest == null
                      ? 'Take your first quiz'
                      : 'Review ${weakest!.name} — your weakest topic',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  weakest == null
                      ? 'Your progress is built from your quiz results.'
                      : 'A short guided practice can build your confidence.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: weakest == null ? 'Take a quiz' : 'Start review',
            onPressed: onStart,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.play_arrow_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.history});

  final QuizHistory history;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Quizzes finished on each day of this week (Monday first).
  List<int> _perDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final r in history.records) {
      final d = r.date.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      final i = day.difference(weekStart).inDays;
      if (i >= 0 && i < 7) counts[i]++;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final perDay = _perDay();
    final weekTotal = perDay.fold<int>(0, (a, b) => a + b);
    final maxCount = perDay.fold<int>(1, (a, b) => b > a ? b : a);
    final streak = history.streakDays;
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: colors.warning,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Study streak: $streak ${streak == 1 ? 'day' : 'days'}',
                style: textTheme.labelMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${history.totalXp} XP',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.tileIcon,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '$weekTotal ${weekTotal == 1 ? 'quiz' : 'quizzes'} this week',
            style: textTheme.bodySmall?.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < _days.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 36 * perDay[index] / maxCount,
                            constraints: const BoxConstraints(minHeight: 3),
                            decoration: BoxDecoration(
                              color: perDay[index] > 0
                                  ? colors.gradientStart
                                  : colors.tile,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _days[index],
                            style: textTheme.labelSmall?.copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.weakest, required this.onStartQuiz});

  final _TopicProgress? weakest;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ProgressCard(
      color: colors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 17, color: colors.info),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI targeted practice',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  weakest == null
                      ? 'Pick a topic and test yourself.'
                      : 'Practice ${weakest!.name} again to boost mastery.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Start quiz',
            onPressed: onStartQuiz,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.14
                  : 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}