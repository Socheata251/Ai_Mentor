import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../data/models/quiz.dart';
import '../providers/quiz_controller.dart';
import 'quiz_history.dart';

/// "Choose a Quiz Topic" - the page shown before a quiz starts.
///
/// Search + level filter, an AI-recommended drill (your weakest topic),
/// the topic list with your results, and Random Mix / Daily Streak buttons.
class TopicPicker extends StatefulWidget {
  const TopicPicker({super.key, required this.topics, required this.onSelect});

  final List<QuizTopic> topics;
  final ValueChanged<QuizTopic> onSelect;

  @override
  State<TopicPicker> createState() => _TopicPickerState();
}

class _TopicPickerState extends State<TopicPicker> {
  static const _levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  final _search = TextEditingController();
  String _level = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- helpers ---------------------------------------------------------

  static int _estMinutes(QuizTopic t) =>
      max(1, (t.count * QuizController.secondsPerQuestion / 60).ceil());

  static int _maxXp(QuizTopic t) =>
      t.count * (QuizController.xpCorrect + QuizController.xpSpeedBonus);

  /// Lowest average accuracy first; topics never taken come before topics
  /// you already know well.
  QuizTopic _recommended(QuizHistory history) {
    QuizTopic? weakest;
    int weakestScore = 101;
    for (final t in widget.topics) {
      final avg = history.averagePercentFor(t.id);
      if (avg == null) continue;
      if (avg < weakestScore) {
        weakestScore = avg;
        weakest = t;
      }
    }
    if (weakest != null && weakestScore < 100) return weakest;
    for (final t in widget.topics) {
      if (history.recordsFor(t.id).isEmpty) return t;
    }
    return widget.topics.first;
  }

  QuizTopic _mix({
    required String id,
    required String title,
    required String subtitle,
    required int questions,
  }) {
    final pool = <QuizQuestion>[
      for (final t in widget.topics) ...t.questions,
    ]..shuffle(Random());
    return QuizTopic(
      id: id,
      title: title,
      subtitle: subtitle,
      category: QuizCategory.mixed,
      level: 'Mixed',
      fileName: 'snippet',
      langBadge: 'MIX',
      questions: pool.take(questions).toList(),
    );
  }

  List<QuizTopic> _filtered() {
    final q = _search.text.trim().toLowerCase();
    return widget.topics.where((t) {
      if (_level != 'All' && t.level != _level) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.level.toLowerCase().contains(q);
    }).toList();
  }

  static IconData _icon(QuizCategory category) => switch (category) {
    QuizCategory.javascript => Icons.javascript_rounded,
    QuizCategory.python => Icons.code_rounded,
    QuizCategory.sql => Icons.storage_rounded,
    QuizCategory.dataStructures => Icons.account_tree_outlined,
    QuizCategory.dynamicProgramming => Icons.bolt_rounded,
    QuizCategory.mixed => Icons.shuffle_rounded,
  };

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final history = QuizHistory.instance;

    return AnimatedBuilder(
      animation: history,
      builder: (context, _) {
        final c = context.colors;
        final text = Theme.of(context).textTheme;
        final topics = _filtered();
        final browsing = _search.text.trim().isEmpty && _level == 'All';
        final recommended = _recommended(history);

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  _Header(onBack: () => Navigator.maybePop(context)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'FACULTY OF COMPUTER STUDIES',
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: c.gradientStart,
                            fontFamily: AppTypography.mono,
                            fontFamilyFallback: AppTypography.monoFallback,
                          ),
                        ),
                      ),
                      const AppPill('Term 2 • 2025', dot: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Choose a Quiz Topic', style: text.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a set of coding questions or a university lab drill to begin.',
                    style: text.bodyMedium?.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _levels.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _LevelChip(
                        label: _levels[i],
                        selected: _level == _levels[i],
                        onTap: () => setState(() => _level = _levels[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (browsing) ...[
                    _RecommendedCard(
                      topic: recommended,
                      accuracy: history.averagePercentFor(recommended.id),
                      minutes: _estMinutes(recommended),
                      onStart: () => widget.onSelect(recommended),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Text(
                        'CURATED CURRICULUM MODULES',
                        style: text.labelSmall?.copyWith(
                          color: c.textStrong,
                          fontFamily: AppTypography.mono,
                          fontFamilyFallback: AppTypography.monoFallback,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${topics.length} ${topics.length == 1 ? 'Track' : 'Tracks'} Available',
                        style: text.labelSmall?.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (topics.isEmpty)
                    const _NoResults()
                  else
                    for (final topic in topics)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TopicCard(
                          topic: topic,
                          icon: _icon(topic.category),
                          minutes: _estMinutes(topic),
                          maxXp: _maxXp(topic),
                          timesTaken: history.recordsFor(topic.id).length,
                          best: history.bestPercentFor(topic.id),
                          recommended: topic.id == recommended.id,
                          onTap: () => widget.onSelect(topic),
                        ),
                      ),
                ],
              ),
            ),
            _BottomBar(
              streak: history.streakDays,
              onRandom: () => widget.onSelect(
                _mix(
                  id: 'mix',
                  title: 'Random Mix',
                  subtitle: 'Questions from every topic',
                  questions: min(8, widget.topics.fold(0, (a, t) => a + t.count)),
                ),
              ),
              onDaily: () => widget.onSelect(
                _mix(
                  id: 'daily',
                  title: 'Daily Streak',
                  subtitle: 'A quick daily practice mix',
                  questions: 5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_rounded, color: c.textStrong),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: c.tile, shape: BoxShape.circle),
          child: Icon(Icons.smart_toy_outlined, size: 20, color: c.tileIcon),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search topics like Python, SQL, JS...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? Icon(Icons.tune_rounded, size: 20, color: c.textSoft)
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.info),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.ink : c.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.ink : c.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? c.onInk : c.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.topic,
    required this.accuracy,
    required this.minutes,
    required this.onStart,
  });

  final QuizTopic topic;
  final int? accuracy; // null = never taken
  final int minutes;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final reason = accuracy == null
        ? "You haven't tried this topic yet. Start a ${topic.count}-question quick drill and kick off your streak!"
        : 'Your weakest topic ($accuracy% accuracy). Start a ${topic.count}-question quick drill to recover confidence and boost your streak!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPill('AI RECOMMENDED FOR YOU', color: c.gradientEnd),
              AppPill(topic.level.toUpperCase(), color: c.danger),
            ],
          ),
          const SizedBox(height: 12),
          Text(topic.title, style: text.titleLarge),
          const SizedBox(height: 6),
          Text(
            reason,
            style: text.bodyMedium?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: c.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${topic.count} Qs • ~$minutes min',
                  style: text.labelMedium?.copyWith(
                    color: c.textMuted,
                    fontFamily: AppTypography.mono,
                    fontFamilyFallback: AppTypography.monoFallback,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: c.ink,
                  foregroundColor: c.onInk,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  'Start Drill',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.icon,
    required this.minutes,
    required this.maxXp,
    required this.timesTaken,
    required this.best,
    required this.recommended,
    required this.onTap,
  });

  final QuizTopic topic;
  final IconData icon;
  final int minutes;
  final int maxXp;
  final int timesTaken;
  final int? best; // null = never taken
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final taken = timesTaken > 0 && best != null;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.tile,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, color: c.tileIcon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topic.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.textSoft),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AppPill(
                    '${topic.level} • ${topic.count} Qs',
                    color: c.textMuted,
                    mono: false,
                    fontSize: 11,
                  ),
                  AppPill(
                    'Est. $minutes min',
                    color: c.textMuted,
                    mono: false,
                    fontSize: 11,
                  ),
                  AppPill(
                    '+$maxXp XP',
                    color: c.gradientEnd,
                    mono: false,
                    fontSize: 11,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: taken
                        ? Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: c.success,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Completed $timesTaken× • Best $best%',
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: c.success,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : recommended
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: AppPill('RECOMMENDED NEXT'),
                          )
                        : Text(
                            'Not attempted yet',
                            style: text.labelMedium?.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    taken ? 'Retake Quiz →' : 'Start Quiz →',
                    style: text.labelMedium?.copyWith(
                      color: c.gradientStart,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: c.textMuted),
          const SizedBox(height: 10),
          Text(
            'No topics match your search',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Try another keyword or level.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.streak,
    required this.onRandom,
    required this.onDaily,
  });

  final int streak;
  final VoidCallback onRandom;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onRandom,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.textStrong,
                side: BorderSide(color: c.border),
                minimumSize: const Size.fromHeight(52),
                shape: shape,
              ),
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: const Text(
                'Random Mix',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: onDaily,
              style: FilledButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.onInk,
                minimumSize: const Size.fromHeight(52),
                shape: shape,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                streak > 0 ? 'Daily Streak (${streak}d)' : 'Daily Streak',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
