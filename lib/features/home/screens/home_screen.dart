import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/router/app_nav.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/stagger_in.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../ai_tutor/screens/chat_prompt_history_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/home_back_glow.dart';
import '../widgets/home_chat_input_bar.dart';
import '../widgets/home_content.dart';
import '../widgets/home_top_bar.dart';
import '../../../data/repositories/user_session.dart';

/// Home dashboard. Layout pieces live in `features/home/widgets/`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName});

  final String? userName;

  /// The name to show: the one passed in, else the signed-in student.
  String get displayName => userName ?? UserSession.instance.name;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // One-shot controller for the staggered entrance
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  // ONE looping controller drives everything that "breathes".
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  // FAST: created once, only drive compositor-level animations.
  late final CurvedAnimation _eased = CurvedAnimation(
    parent: _loop,
    curve: Curves.easeInOut,
  );
  late final Animation<double> _pulse = Tween<double>(
    begin: 0.75,
    end: 1.0,
  ).animate(_eased);
  late final Animation<Offset> _logoFloat = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.0625), // ~6px on a 96px logo
  ).animate(_eased);

  // FAST: stagger animations are built ONCE here, not on every build().
  late final List<CurvedAnimation> _fades = List.generate(8, (i) {
    final start = math.min(i * 0.08, 0.55);
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(start, start + 0.45, curve: Curves.easeOutCubic),
    );
  });

  final _scroll = ScrollController();
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/logo.png'), context);
  }

  @override
  void dispose() {
    for (final f in _fades) {
      f.dispose();
    }
    _eased.dispose();
    _intro.dispose();
    _loop.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------

  /// Open a screen on top of Home (the menu itself lives in [AppShell]).
  void _push(Widget screen) {
    Navigator.push(context, smoothPageRoute(builder: (_) => screen));
  }

  void _openSchedule() => _push(const ScheduleScreen());
  void _openHistory() => _push(const ChatPromptHistoryScreen());
  void _openSettings() => _push(const SettingsScreen());

  void _newChat() => AppNav.newChat(context, userName: widget.displayName);

  void _openTutorWithAsk(String question) => _push(
    AiTutorScreen(
      userName: widget.displayName,
      useDemo: false,
      initialPrompt: question,
    ),
  );

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = context.screenSize;

    // The drawer / sidebar comes from AppShell (same on every screen).
    return ListenableBuilder(
      listenable: UserSession.instance, // refresh greeting after profile edit
      builder: (context, _) => AppShell(
        selectedIndex: 0,
        userName: widget.displayName,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: colors.pageGradient),
            child: SafeArea(child: _buildMain(size)),
          ),
        ),
      ),
    );
  }

  Widget _buildMain(ScreenSize size) {
    final side = size.pick(compact: 16.0, medium: 24.0, expanded: 32.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.pick(compact: 600.0, medium: 680.0, expanded: 1080.0),
        ),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Soft blue glow behind the logo. FAST: the gradient is static;
            // the scroll only moves a Transform and the pulse is a fade.
            Positioned(
              top: -28,
              left: 0,
              right: 0,
              height: 340,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _scroll,
                  child: RepaintBoundary(
                    child: FadeTransition(
                      opacity: _pulse,
                      child: const Center(child: HomeBackGlow()),
                    ),
                  ),
                  builder: (context, glow) {
                    final off = _scroll.hasClients ? _scroll.offset : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -off),
                      child: glow,
                    );
                  },
                ),
              ),
            ),

            // Top bar + scrolling content
            Column(
              children: [
                // FAST: own layer, so scrolling never repaints it
                RepaintBoundary(
                  child: StaggerIn(
                    animation: _fades[0],
                    child: HomeTopBar(
                      onNewChat: _newChat,
                      onHistory: _openHistory,
                      onSettings: _openSettings,
                      horizontalPadding: side,
                    ),
                  ),
                ),
                Expanded(
                  child: HomeContent(
                    size: size,
                    scroll: _scroll,
                    fades: _fades,
                    logoFloat: _logoFloat,
                    greeting: _greeting,
                    userName: widget.displayName,
                    onViewSchedule: _openSchedule,
                  ),
                ),
              ],
            ),

            // Floating chat input (own layer, list scrolling never repaints it)
            Positioned(
              left: side,
              right: side,
              bottom: 12,
              child: RepaintBoundary(
                child: StaggerIn(
                  animation: _fades[6],
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: HomeChatInputBar(onAsk: _openTutorWithAsk),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}