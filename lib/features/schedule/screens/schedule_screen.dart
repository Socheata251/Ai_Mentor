import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/round_icon_button.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final sessions = <_SessionData>[
      _SessionData(
        title: 'Daily Coding Brief',
        subtitle:
            'Personalized morning briefing on Data Structures and clean coding habits.',
        time: 'Daily at 7:00 AM',
        tag: 'High Priority',
        color: const Color(0xFF3C82F6),
        icon: Icons.code_rounded,
      ),
      _SessionData(
        title: 'Weekend Long Code Lab',
        subtitle:
            'Every Saturday at 9:00 AM, dive deep into practical database management and SQL optimization exercises.',
        time: 'Every Saturday',
        tag: '2.5 hrs',
        color: const Color(0xFF10B981),
        icon: Icons.terminal_rounded,
      ),
      _SessionData(
        title: 'Exam & Assignment Monitor',
        subtitle:
            'Track CS 204 Computer Architecture and Operating Systems assignment deadlines and exam prep milestones.',
        time: 'Deadline in 3 days',
        tag: 'Check now',
        color: const Color(0xFFF59E0B),
        icon: Icons.event_note_rounded,
      ),
      _SessionData(
        title: 'Quiz & Flashcards',
        subtitle:
            'Short revision rounds to lock in key concepts before your next study sprint.',
        time: 'Quick review',
        tag: '12 cards',
        color: const Color(0xFF8B5CF6),
        icon: Icons.quiz_rounded,
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.maybePop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Scheduled',
                            textAlign: TextAlign.center,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.textStrong,
                            ),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.filter_list_rounded,
                          tooltip: 'Filter',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ACLEDIA University • Semester 4',
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textStrong,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.tile,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'AI route',
                              style: text.labelSmall?.copyWith(
                                color: colors.tileIcon,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: session.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  session.icon,
                                  color: session.color,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            session.title,
                                            style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: colors.textStrong,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: colors.textMuted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      session.subtitle,
                                      style: text.bodySmall?.copyWith(
                                        color: colors.textMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        Text(
                                          session.time,
                                          style: text.labelSmall?.copyWith(
                                            color: colors.textSoft,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.tile,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            session.tag,
                                            style: text.labelSmall?.copyWith(
                                              color: colors.tileIcon,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class _SessionData {
  const _SessionData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tag,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String time;
  final String tag;
  final Color color;
  final IconData icon;
}
