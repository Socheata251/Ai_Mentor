import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/router/smooth_page_route.dart';
import '../core/widgets/brand_logo.dart';
import '../features/ai_tutor/screens/ai_tutor_screen.dart';
import '../features/ai_tutor/screens/chat_prompt_history_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/settings/screens/settings_screen.dart';

const _serif = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif'],
);

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

  // FAST: these are created once and only drive compositor-level
  // animations (fade / slide). Nothing is repainted per frame.
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

  // Which drawer item is highlighted. Only the drawer list listens to it.
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
    precacheImage(AssetImage("assets/logo.png"), context);
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

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onDrawerSelect(int i) {
    _drawerIndex.value = i;
    _scaffoldKey.currentState?.closeDrawer();
    switch (i) {
      case 1:
        _openTutor();
      case 2:
        _openQuiz();
      case 3:
        _openHistory();
      case 4:
        _openLibrary();
      case 5:
        _openProgress();
      case 6:
        _openSchedule();
      case 7:
        _openSettings();
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const ChatPromptHistoryScreen()),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openLibrary() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const LibraryScreen()),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openTutor() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => AiTutorScreen(userName: widget.userName)),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openTutorWithAsk(String question) {
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) => AiTutorScreen(
          userName: widget.userName,
          useDemo: false,
          initialPrompt: question,
        ),
      ),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openQuiz() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const QuizScreen()),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openSettings() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openProgress() {
    Navigator.push(
      context,
      smoothPageRoute(
        builder: (_) => ProgressScreen(userName: widget.userName),
      ),
    ).then((_) => _drawerIndex.value = 0);
  }

  void _openSchedule() {
    Navigator.push(
      context,
      smoothPageRoute(builder: (_) => const ScheduleScreen()),
    ).then((_) => _drawerIndex.value = 0);
  }

  /// Fade + slide-up. FadeTransition avoids the offscreen layer that
  /// `Opacity` creates, and [child] is built once (not every frame).
  Widget _stagger(int i, Widget child) {
    final anim = _fades[i];
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (context, c) => Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: c,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        userName: widget.userName,
        selected: _drawerIndex,
        onSelect: _onDrawerSelect,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // Soft blue glow behind the logo. FAST: the gradient is
                  // static + cached; the scroll only moves a Transform and
                  // the pulse is a FadeTransition.
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
                            child: const Center(child: _BackGlow()),
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
                        child: _stagger(0, _TopBar(onMenu: _openDrawer)),
                      ),
                      Expanded(
                        // FAST: ListView builds only what is visible and
                        // wraps every child in its own RepaintBoundary
                        // (SingleChildScrollView did neither).
                        child: ListView(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                          children: [
                            const SizedBox(height: 24),
                            _stagger(
                              1,
                              Column(
                                children: [
                                  _FloatingLogo(float: _logoFloat),
                                  const SizedBox(height: 14),
                                  const _Tagline(),
                                  const SizedBox(height: 14),
                                  _Greeting(
                                    greeting: _greeting,
                                    name: widget.userName,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _stagger(2, const _UpgradeCard()),
                            const SizedBox(height: 16),
                            _stagger(3, const _QuickActions()),
                            const SizedBox(height: 24),
                            _stagger(
                              4,
                              _SectionHeader(
                                title: "Today's Schedule",
                                action: 'View All',
                                onTap: _openSchedule,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _stagger(4, const _ScheduleCard()),
                            const SizedBox(height: 12),
                            _stagger(5, const _InsightCard()),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Floating chat input.
                  // FAST: own layer, so list scrolling never repaints it.
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: RepaintBoundary(
                      child: _stagger(
                        6,
                        _ChatInputBar(onAsk: _openTutorWithAsk),
                      ),
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

/// Static radial glow (const -> built once, cached by a RepaintBoundary).
class _BackGlow extends StatelessWidget {
  const _BackGlow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 340,
      height: 340,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x6E6C93FF), Color(0x1F6C93FF), Color(0x006C93FF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Shared building blocks
// =====================================================================

/// Theme-aware rounded card with a soft shadow.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Wraps any widget so it shrinks slightly while pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.scale = 0.95});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// Top bar
// =====================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenu});

  /// Opens the drawer.
  final VoidCallback onMenu;

  Widget _bar(double w, Color color) => Container(
    width: w,
    height: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button (two bars, like the design)
          Semantics(
            key: const ValueKey('navigation-menu'),
            button: true,
            label: 'Open navigation menu',
            child: _Pressable(
              onTap: onMenu,
              child: _RoundButton(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(16, colors.textStrong),
                    const SizedBox(height: 4),
                    _bar(10, colors.textStrong),
                  ],
                ),
              ),
            ),
          ),

          // "AI STUDY MODE" pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI STUDY MODE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.textStrong,
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.float});
  final Animation<Offset> float;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 440.0;
        final logoSize = (availableWidth * 0.37).clamp(124.0, 150.0).toDouble();
        return SizedBox(
          height: logoSize + 8,
          child: Center(
            child: RepaintBoundary(
              child: SlideTransition(
                position: float,
                child: BrandLogo(size: logoSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavLogo(size: 22, color: colors.textStrong),
          const SizedBox(width: 8),
          Text(
            'PERSONAL KNOWLEDGE COMPANION',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.name});

  final String greeting, name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          '$greeting,',
          style: _serif.copyWith(
            color: colors.textStrong,
            fontSize: 30,
            height: 1.1,
          ),
        ),
        Text(
          name,
          style: _serif.copyWith(
            color: colors.textStrong,
            fontSize: 30,
            height: 1.15,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ready to start studying with AUB today?',
          style: TextStyle(fontSize: 12.5, color: colors.textMuted),
        ),
      ],
    );
  }
}

// =====================================================================
// Upgrade card
// =====================================================================

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NavLogo(size: 24, color: colors.gradientStart),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Get more with AUB Mentor Pro',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Unlimited questions & faster deep-solve model',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Pressable(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: colors.onInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Quick actions: Explain / Summarize / Solve / Quiz
// =====================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const items = [
      _QuickAction(label: 'Explain', icon: Icons.menu_book_outlined),
      _QuickAction(label: 'Summarize', icon: Icons.description_outlined),
      _QuickAction(label: 'Solve', symbol: '√x'),
      _QuickAction(label: 'Quiz', icon: Icons.psychology_outlined),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, this.icon, this.symbol});

  final String label;
  final IconData? icon;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Pressable(
      onTap: () {
        // TODO: open the matching tool
      },
      child: AspectRatio(
        aspectRatio: 0.78,
        child: _Card(
          padding: const EdgeInsets.all(6),
          radius: 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.tile,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: symbol != null
                    ? Text(
                        symbol!,
                        style: TextStyle(
                          color: colors.tileIcon,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : Icon(icon, color: colors.tileIcon, size: 21),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Schedule + AI insight
// =====================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onTap});

  final String title, action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textStrong,
          ),
        ),
        _Pressable(
          onTap: onTap ?? () {},
          child: Text(
            action,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: colors.info,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Pressable(
      scale: 0.98,
      onTap: () {},
      child: _Card(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _ProgressRing(value: 0.75),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculus – Limits & Continuity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '45 Min Left',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress that animates from 0 to [value] when it appears.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 46,
      height: 46,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _RingPainter(t, colors.border, colors.gradientStart),
          child: Center(
            child: Text(
              '${(t * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.trackColor, this.progressColor);
  final double value;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NavLogo(size: 24, color: colors.gradientStart),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  color: colors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "You're spending more time on your weak topics. Keep it up! "
            'Mastery on differentiation will follow.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    widget.onAsk(question);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: NavLogo(size: 42, color: Colors.white),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(fontSize: 14, color: colors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: colors.textStrong),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => _Pressable(
              onTap: value.text.trim().isEmpty ? null : _submit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value.text.trim().isEmpty ? colors.tile : colors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: value.text.trim().isEmpty
                      ? colors.tileIcon
                      : colors.onInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.userName,
    required this.selected,
    required this.onSelect,
  });

  final String userName;
  final ValueListenable<int> selected;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (Icons.home_outlined, 'Home'),
    (Icons.auto_awesome_outlined, 'AI Tutor'),
    (Icons.quiz_outlined, 'Quiz'),
    (Icons.history_rounded, 'History'),
    (Icons.local_library_outlined, 'Library'),
    (Icons.insights_outlined, 'Progress'),
    (Icons.event_note_outlined, 'Scheduled'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Drawer(
      width: 304,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F7CFF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: NavLogo(size: 74, color: colors.gradientStart),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Astra Learn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hi, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Items (ListView.builder: built lazily)
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, sel, _) => ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final (icon, label) = _items[i];
                    return Column(
                      children: [
                        // thin divider before Settings
                        if (i == _items.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Divider(height: 1, color: colors.border),
                          ),
                        _DrawerTile(
                          icon: icon,
                          label: label,
                          selected: i == sel,
                          onTap: () => onSelect(i),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Astra Learn  ·  v1.0.0',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Pressable(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? colors.onInk.withValues(alpha: 0.16)
                    : colors.tile,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? colors.onInk : colors.tileIcon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.onInk : colors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
