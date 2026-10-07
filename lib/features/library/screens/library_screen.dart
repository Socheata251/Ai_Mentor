import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../data/models/course.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../providers/library_controller.dart';
import '../widgets/course_tile.dart';
import '../widgets/exam_banner.dart';
import '../widgets/library_search_bar.dart';
import '../widgets/semester_filter_bar.dart';
import '../widgets/university_card.dart';
import '../../../core/widgets/app_shell.dart';

/// Library: curriculum modules with search + semester filter.
/// The ☰ menu button comes from [AppShell].
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _library = LibraryController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _library.dispose();
    _search.dispose();
    super.dispose();
  }

  void _openCourse(Course course) {
    // Opens the AI tutor on this course's topic.
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) => AiTutorScreen(topic: course.title, useDemo: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppShell(selectedIndex: 4, child: Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.pageGradient),
        child: SafeArea(
          child: Center(
            // iPad: keep the content in a readable column.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _library,
                      builder: (context, _) => _buildList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: LibrarySearchBar(
                      controller: _search,
                      onChanged: _library.setQuery,
                      onAdd: () => showComingSoon(context, 'Adding notes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildList() {
    final courses = _library.courses;
    final n = courses.length;
    // rows: 0 university · 1 filters · 2 section header · courses (or empty) · banner
    final courseRows = n == 0 ? 1 : n;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 3 + courseRows + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: UniversityCard(),
          );
        }
        if (i == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SemesterFilterBar(
              semesters: _library.semesters,
              selected: _library.selectedSemester,
              onSelect: _library.selectSemester,
            ),
          );
        }
        if (i == 2) {
          return _SectionHeader(
            count: n,
            onSyllabus: () => showComingSoon(context, 'Syllabus PDF'),
          );
        }
        if (i == 3 + courseRows) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ExamBanner(
              onStart: () => showComingSoon(context, 'AI mock quiz'),
              // TODO: open the Quiz generator once that screen exists.
            ),
          );
        }
        if (n == 0) return const _EmptyResults();

        final course = courses[i - 3];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Reveal(
            key: ValueKey(course.code),
            index: i - 3,
            child: CourseTile(course: course, onTap: () => _openCourse(course)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const AppMenuButton(keepSpace: true),
          Expanded(
            child: Text(
              'Library',
              textAlign: TextAlign.center,
              style: t.titleLarge,
            ),
          ),
          RoundIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'More',
            onTap: () => showComingSoon(context, 'Saved lessons'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count, required this.onSyllabus});

  final int count;
  final VoidCallback onSyllabus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Curriculum Modules ($count Active)',
            style: t.bodySmall!.copyWith(fontSize: 12),
          ),
          GestureDetector(
            onTap: onSyllabus,
            child: Text(
              'Syllabus PDF',
              style: t.labelMedium!.copyWith(
                color: c.gradientStart,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: c.textMuted),
          const SizedBox(height: 10),
          Text('No courses found', style: t.titleSmall),
          const SizedBox(height: 4),
          Text('Try another search or semester.', style: t.bodySmall),
        ],
      ),
    );
  }
}

/// Fade + slide-up when a tile first appears (first 8 only, so it stays cheap).
class _Reveal extends StatelessWidget {
  const _Reveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index > 7) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
    );
  }
}