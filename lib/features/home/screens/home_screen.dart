import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/router/smooth_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/stagger_in.dart';
import '../../../data/repositories/chat_conversation_history.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../ai_tutor/screens/chat_prompt_history_screen.dart';
import '../../library/screens/library_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/home_back_glow.dart';
import '../widgets/home_chat_input_bar.dart';
import '../widgets/home_content.dart';
import '../widgets/home_top_bar.dart';

/// Home dashboard. Layout pieces live in `features/home/widgets/`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName = 'Bunthoeun'});

  final String userName;

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Which drawer item is highlighted. Only the menu list listens to it.
  final ValueNotifier<int> _drawerIndex = ValueNotifier<int>(0);

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
    _drawerIndex.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onMenuSelect(int i) {
    _drawerIndex.value = i;
    _scaffoldKey.currentState?.closeDrawer();
    switch (i) {
      case 1:
        _push(AiTutorScreen(userName: widget.userName));
      case 2:
        _push(const QuizScreen());
      case 3:
        _push(const ChatPromptHistoryScreen());
      case 4:
        _push(const LibraryScreen());
      case 5:
        _push(ProgressScreen(userName: widget.userName));
      case 6:
        _push(const ScheduleScreen());
      case 7:
        _push(const SettingsScreen());
    }
  }

  /// Open a screen, then highlight "Home" again when we come back.
  void _push(Widget screen) {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => screen),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openSchedule() => _push(const ScheduleScreen());
  void _openHistory() => _push(const ChatPromptHistoryScreen());
  void _openSettings() => _push(const SettingsScreen());

  /// Start a fresh, empty chat (like "New chat" in ChatGPT).
  void _newChat() {
    _scaffoldKey.currentState?.closeDrawer();
    _push(AiTutorScreen(userName: widget.userName, useDemo: false));
  }

  /// Re-open a saved chat from the "Recent chats" list.
  void _openChat(ChatConversation chat) {
    _scaffoldKey.currentState?.closeDrawer();
    _push(
      AiTutorScreen(
        userName: widget.userName,
        useDemo: false,
        conversationId: chat.id,
        initialMessages: chat.messages,
      ),
    );
  }

  void _openTutorWithAsk(String question) => _push(
    AiTutorScreen(
      userName: widget.userName,
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
    final hasSidebar = size.isExpanded;

    return Scaffold(
      key: _scaffoldKey,
      // Desktop shows a permanent sidebar instead of the slide-in drawer.
      drawer: hasSidebar
          ? null
          : AppDrawer(
              userName: widget.userName,
              selected: _drawerIndex,
              onSelect: _onMenuSelect,
              onNewChat: _newChat,
              onOpenChat: _openChat,
            ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageGradient),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSidebar)
                HomeSideBar(
                  userName: widget.userName,
                  selected: _drawerIndex,
                  onSelect: _onMenuSelect,
                  onNewChat: _newChat,
                  onOpenChat: _openChat,
                ),
              Expanded(child: _buildMain(size)),
            ],
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
                      onMenu: _openDrawer,
                      onNewChat: _newChat,
                      onHistory: _openHistory,
                      onSettings: _openSettings,
                      showMenu: !size.isExpanded,
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
                    userName: widget.userName,
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