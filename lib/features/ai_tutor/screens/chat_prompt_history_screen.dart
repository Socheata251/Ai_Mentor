import 'package:flutter/material.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/models/quiz.dart';
import '../../../data/repositories/chat_conversation_history.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../quiz/widgets/quiz_history.dart';
import 'ai_tutor_screen.dart';
import '../../../core/widgets/app_shell.dart';

enum _Filter { all, chats, quizzes }

/// One row of the history: either an AI chat or a finished quiz.
class _Entry {
  _Entry.chat(ChatConversation this.chat)
    : date = chat.updatedAt,
      quiz = null;
  _Entry.quiz(QuizRecord this.quiz)
    : date = quiz.date,
      chat = null;

  final DateTime date;
  final ChatConversation? chat;
  final QuizRecord? quiz;
}

class _Group {
  _Group(this.label, this.dateText);
  final String label;
  final String? dateText;
  final List<_Entry> entries = [];
}

/// "Chat & Practice History": AI tutor chats and quiz sessions in one
/// searchable timeline, grouped by day.
class ChatPromptHistoryScreen extends StatefulWidget {
  const ChatPromptHistoryScreen({super.key});

  @override
  State<ChatPromptHistoryScreen> createState() =>
      _ChatPromptHistoryScreenState();
}

class _ChatPromptHistoryScreenState extends State<ChatPromptHistoryScreen> {
  final _search = TextEditingController();
  final _starred = <String>{};
  _Filter _filter = _Filter.all;

  late final Listenable _sources = Listenable.merge([
    ChatConversationHistory.instance,
    QuizHistory.instance,
  ]);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- actions ---------------------------------------------------------

  void _openConversation(ChatConversation conversation) {
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) => AiTutorScreen(
          topic: 'Chat history',
          useDemo: false,
          conversationId: conversation.id,
          initialMessages: conversation.messages,
        ),
      ),
    );
  }

  void _retake(QuizRecord record) {
    final isMix = record.category == QuizCategory.mixed;
    Navigator.push(
      context,
      smoothPageRoute<void>(
        builder: (_) =>
            QuizScreen(initialTopicId: isMix ? null : record.topicId),
      ),
    );
  }

  void _toggleStar(String id) {
    setState(() {
      if (!_starred.remove(id)) _starred.add(id);
    });
  }

  void _delete(String id) {
    _starred.remove(id);
    ChatConversationHistory.instance.remove(id);
  }

  // ---- data ------------------------------------------------------------

  List<_Entry> _entries({required bool chats, required bool quizzes}) {
    final query = _search.text.trim().toLowerCase();
    final list = <_Entry>[];

    if (chats) {
      for (final chat in ChatConversationHistory.instance.conversations) {
        final match =
            query.isEmpty ||
            chat.messages.any((m) => m.plainText.toLowerCase().contains(query));
        if (match) list.add(_Entry.chat(chat));
      }
    }
    if (quizzes) {
      for (final record in QuizHistory.instance.records) {
        final match =
            query.isEmpty || record.topicTitle.toLowerCase().contains(query);
        if (match) list.add(_Entry.quiz(record));
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<_Group> _group(List<_Entry> entries) {
    final groups = <_Group>[];
    for (final entry in entries) {
      final label = _dayLabel(entry.date);
      final dateText = (label == 'Today' || label == 'Yesterday')
          ? _fullDate(entry.date)
          : null;
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_Group(label, dateText));
      }
      groups.last.entries.add(entry);
    }
    return groups;
  }

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppShell(selectedIndex: 3, child: Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _sources,
          builder: (context, _) {
            final chatCount = ChatConversationHistory.instance.conversations.length;
            final quizCount = QuizHistory.instance.quizzesTaken;
            final entries = _entries(
              chats: _filter != _Filter.quizzes,
              quizzes: _filter != _Filter.chats,
            );
            final groups = _group(entries);
            final searching = _search.text.trim().isNotEmpty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const _TopBar(),
                const SizedBox(height: 4),
                _SearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _InfoPill(
                      label: 'Semester 4 • Spring 2025',
                      icon: Icons.school_rounded,
                    ),
                    _InfoPill(label: 'ACLEDA IT Lab', dotColor: c.success),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All History',
                        count: chatCount + quizCount,
                        selected: _filter == _Filter.all,
                        onTap: () => setState(() => _filter = _Filter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'AI Chats',
                        count: chatCount,
                        selected: _filter == _Filter.chats,
                        onTap: () => setState(() => _filter = _Filter.chats),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Quizzes',
                        count: quizCount,
                        selected: _filter == _Filter.quizzes,
                        onTap: () => setState(() => _filter = _Filter.quizzes),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  sessions: chatCount + quizCount,
                  average: QuizHistory.instance.averagePercent,
                  xp: QuizHistory.instance.totalXp,
                ),
                const SizedBox(height: 16),
                if (groups.isEmpty)
                  _EmptyState(searching: searching, filter: _filter)
                else
                  for (final group in groups) ...[
                    _GroupHeader(group: group),
                    const SizedBox(height: 8),
                    for (final entry in group.entries) ...[
                      if (entry.chat != null)
                        _ChatCard(
                          conversation: entry.chat!,
                          starred: _starred.contains(entry.chat!.id),
                          onOpen: () => _openConversation(entry.chat!),
                          onToggleStar: () => _toggleStar(entry.chat!.id),
                          onDelete: () => _delete(entry.chat!.id),
                        )
                      else
                        _QuizCard(
                          record: entry.quiz!,
                          onRetake: () => _retake(entry.quiz!),
                        ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                  ],
                const _StorageNote(),
              ],
            );
          },
        ),
      ),
    ));
  }

  // ---- date helpers ----------------------------------------------------

  static String _dayLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'Earlier this week';
    return _fullDate(local);
  }

  static String _fullDate(DateTime date) {
    final d = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Header pieces
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        const AppMenuButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Chat & Practice History',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: c.tile,
          child: Icon(Icons.person_rounded, size: 20, color: c.tileIcon),
        ),
        const SizedBox(width: 4),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search conversations, quizzes, topics...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
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
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.info),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.icon, this.dotColor});

  final String label;
  final IconData? icon;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.tileIcon),
            const SizedBox(width: 6),
          ],
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: c.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? c.onInk : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.sessions,
    required this.average,
    required this.xp,
  });

  final int sessions;
  final int? average; // null = no quiz yet
  final int xp;

  static String _grade(int percent) {
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: c.tile,
                child: Icon(Icons.flash_on_rounded, color: c.tileIcon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Study Sync Active', style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'CS Lab Node 04 • Continuous Track',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.gradientEnd.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  average == null ? 'No grade yet' : 'Grade ${_grade(average!)}',
                  style: text.labelSmall?.copyWith(
                    color: c.gradientEnd,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(value: '$sessions', label: 'Sessions Done'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: average == null ? '—' : '$average%',
                  label: 'Quiz Avg',
                  accent: c.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: '$xp',
                  label: 'Total XP',
                  accent: c.gradientEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: c.tile.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: text.headlineSmall?.copyWith(
              color: accent ?? c.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _Group group;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final count = group.entries.length;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c.info, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(group.label, style: text.titleSmall),
        if (group.dateText != null) ...[
          const SizedBox(width: 8),
          Text(group.dateText!, style: text.bodySmall),
        ],
        const Spacer(),
        Text(
          '$count ${count == 1 ? 'entry' : 'entries'}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 0.2,
              fontFamily: AppTypography.mono,
              fontFamilyFallback: AppTypography.monoFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: c.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: c.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: c.textStrong,
        backgroundColor: c.tile,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm - 4),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.conversation,
    required this.starred,
    required this.onOpen,
    required this.onToggleStar,
    required this.onDelete,
  });

  final ChatConversation conversation;
  final bool starred;
  final VoidCallback onOpen;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final title = conversation.title.trim().isEmpty
        ? 'New conversation'
        : conversation.title.trim();
    final count = conversation.messages.length;

    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(
                label: 'AI Tutor Chat',
                icon: Icons.chat_bubble_outline_rounded,
                color: c.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${formatRelative(conversation.updatedAt.toLocal())} • $count msgs',
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ),
              if (starred)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.star_rounded, size: 20, color: c.warning),
                ),
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: 'More',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: c.textMuted,
                  ),
                  onSelected: (value) {
                    if (value == 'star') onToggleStar();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'star',
                      child: Text(starred ? 'Remove star' : 'Star'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium,
          ),
          const SizedBox(height: 2),
          Text('AI Tutor • $count messages', style: text.bodySmall),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.tile.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.sm - 4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: c.gradientStart,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conversation.preview.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _SoftButton(label: 'Open Thread', onTap: onOpen),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.record, required this.onRetake});

  final QuizRecord record;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final percent = (record.percent * 100).round();
    final scoreColor = record.percent >= 0.8
        ? c.success
        : record.percent >= 0.5
        ? c.warning
        : c.danger;

    return _CardShell(
      onTap: onRetake,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(
                label: 'Quiz Session',
                icon: Icons.quiz_outlined,
                color: c.gradientEnd,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatRelative(record.date.toLocal()),
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${record.score}/${record.total} ($percent%)',
                  style: text.labelMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.topicTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium,
          ),
          const SizedBox(height: 2),
          Text('Quiz • +${record.xp} XP earned', style: text.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: record.percent,
              minHeight: 6,
              backgroundColor: c.tile,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: c.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${record.score} of ${record.total} correct',
                  style: text.labelMedium?.copyWith(color: c.textMuted),
                ),
              ),
              _SoftButton(label: 'Retake Quiz', onTap: onRetake),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state + footer
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.filter});

  final bool searching;
  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final what = switch (filter) {
      _Filter.all => 'history',
      _Filter.chats => 'AI chats',
      _Filter.quizzes => 'quizzes',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: c.textMuted),
          const SizedBox(height: 12),
          Text(
            searching ? 'No matching $what' : 'No $what yet',
            style: text.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? 'Try another search term.'
                : 'Your AI tutor chats and finished quizzes will appear here.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StorageNote extends StatelessWidget {
  const _StorageNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tile.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 20, color: c.tileIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'History is kept on this device while the app is open and '
              'resets when you close it.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}