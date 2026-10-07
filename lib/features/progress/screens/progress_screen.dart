import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../data/repositories/user_session.dart';

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

  static const _topics = <_TopicProgress>[
    _TopicProgress('Variables', 0.90),
    _TopicProgress('Loops', 0.80),
    _TopicProgress('Recursion', 0.45, warning: true),
    _TopicProgress('Object-Oriented (OOP)', 0.88),
    _TopicProgress('Data Structures (Trees & Sorting)', 0.85, warning: true),
  ];

  void _openTutor() {
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) => AiTutorScreen(
          userName: widget.displayName,
          useDemo: false,
          topic: 'Recursion',
          initialPrompt: 'Help me review recursion. Start with a hint.',
        ),
      ),
    );
  }

  void _openQuiz() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return AppShell(
      selectedIndex: 5,
      userName: widget.displayName,
      child: Container(
      decoration: BoxDecoration(gradient: colors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _SummaryCard(term: _term),
                    const SizedBox(height: 12),
                    _TopicsCard(topics: _topics),
                    const SizedBox(height: 12),
                    _RecommendationCard(onStart: _openTutor),
                    const SizedBox(height: 12),
                    const _StreakCard(),
                    const SizedBox(height: 12),
                    _PracticeCard(onStartQuiz: _openQuiz),
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
                constraints: const BoxConstraints(maxWidth: 568),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openQuiz,
                    icon: const Icon(Icons.quiz_outlined, size: 17),
                    label: const Text('Generate Quiz on Recursion (10 Qs)'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  value: term == 'Last Term' ? '28' : '34',
                  icon: Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Accuracy',
                  value: term == 'Last Term' ? '68%' : '72%',
                  detail: '+4% this week',
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
  const _TopicsCard({required this.topics});

  final List<_TopicProgress> topics;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topics covered', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
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
              Text('5 topics', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicProgress {
  const _TopicProgress(this.name, this.value, {this.warning = false});

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
  const _RecommendationCard({required this.onStart});

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
                  'Review recursion — your weakest topic',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  'A short guided practice can build your confidence.',
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
            tooltip: 'Start recursion review',
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
  const _StreakCard();

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _hours = [1.2, 2.2, 3.2, 1.8, 3.3, 0.25, 0.15];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
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
              Text('Study streak: 5 days', style: textTheme.labelMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Top 15%',
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
            'Total time spent: 4h 25m this week',
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
                            height: 36 * _hours[index] / 3.3,
                            constraints: const BoxConstraints(minHeight: 3),
                            decoration: BoxDecoration(
                              color: index == 2 || index == 4
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
  const _PracticeCard({required this.onStartQuiz});

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
                  'Solve 10 tailored recursion challenges to boost mastery.',
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