import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/widgets/stagger_in.dart';
import 'home_hero.dart';
import 'insight_card.dart';
import 'quick_actions.dart';
import 'schedule_card.dart';
import 'section_header.dart';
import 'upgrade_card.dart';

/// The scrolling part of the home screen.
///   phone / tablet -> one column
///   desktop        -> two columns (hero + upgrade | actions + schedule)
/// To reorder or add a section, edit the helper methods below.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.size,
    required this.scroll,
    required this.fades,
    required this.logoFloat,
    required this.greeting,
    required this.userName,
    required this.onViewSchedule,
  });

  final ScreenSize size;
  final ScrollController scroll;
  final List<Animation<double>> fades;
  final Animation<Offset> logoFloat;
  final String greeting;
  final String userName;
  final VoidCallback onViewSchedule;

  // ---- sections (each one wrapped with its entrance animation) ----

  Widget _hero() => StaggerIn(
    animation: fades[1],
    child: HomeHero(
      float: logoFloat,
      greeting: greeting,
      name: userName,
      maxLogoSize: size.pick(compact: 150, medium: 170, expanded: 190),
      titleSize: size.pick(compact: 30, medium: 34, expanded: 38),
    ),
  );

  Widget _upgrade() => StaggerIn(animation: fades[2], child: const UpgradeCard());

  Widget _actions() => StaggerIn(animation: fades[3], child: const QuickActions());

  Widget _scheduleHeader() => StaggerIn(
    animation: fades[4],
    child: SectionHeader(
      title: "Today's Schedule",
      action: 'View All',
      onTap: onViewSchedule,
    ),
  );

  Widget _scheduleCard() =>
      StaggerIn(animation: fades[4], child: const ScheduleCard());

  Widget _insight() => StaggerIn(animation: fades[5], child: const InsightCard());

  // ---- layouts ----

  List<Widget> _oneColumn() => [
    _hero(),
    const SizedBox(height: 24),
    _upgrade(),
    const SizedBox(height: 16),
    _actions(),
    const SizedBox(height: 24),
    _scheduleHeader(),
    const SizedBox(height: 12),
    _scheduleCard(),
    const SizedBox(height: 12),
    _insight(),
  ];

  Widget _twoColumns() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 5,
        child: Column(children: [_hero(), const SizedBox(height: 24), _upgrade()]),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 6,
        child: Column(
          children: [
            _actions(),
            const SizedBox(height: 24),
            _scheduleHeader(),
            const SizedBox(height: 12),
            _scheduleCard(),
            const SizedBox(height: 12),
            _insight(),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final side = size.pick(compact: 16.0, medium: 24.0, expanded: 32.0);
    final bottom = size.pick(compact: 200.0, medium: 160.0, expanded: 140.0);

    // FAST: ListView builds only what is visible and wraps every child in
    // its own RepaintBoundary.
    return ListView(
      controller: scroll,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(side, 0, side, bottom),
      children: [
        const SizedBox(height: 24),
        if (size.isExpanded) _twoColumns() else ..._oneColumn(),
      ],
    );
  }
}
